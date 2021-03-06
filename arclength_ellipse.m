function [arclength] = arclength_ellipse(a, b, theta0, theta1)
%ARCLENGTH_ELLIPSE Calculates the arclength of ellipse.
%
%   ARCLENGTH_ELLIPSE(A, B, THETA0, THETA1) Calculates the arclength of ellipse 
%   using the precise formulas based on the representation of 
%   the arclength by the Elliptic integral of the second kind.
%
%   Ellipse parameters:
%       T - measured in radians from 0 in the positive direction, 
%           Period: 2*Pi
%       A - major axis
%       B - minor axis
%   
%   Parametric equations:
%       x(t) = a.cos(t)
%       y(t) = b.sin(t)
%
%   Cartesian equation:
%   x^2/a^2 + y^2/b^2 = 1
%
%   Eccentricity:
%       e = Sqrt(1 - (a/b)^2)
%
%   Focal parameter:
%       b^2/Sqrt(a^2 - b^2)
%
%   Foci:
%       (-Sqrt(a^2 - b^2), 0)   OR   (Sqrt(a^2 - b^2), 0)
%
%   Arclength:
%       b*EllipticE( t, 1 - (a/b)^2 )
%
%   Mathematica Test 1:
%       In:= b = 10; a = 5;
%            SetPrecision[b*EllipticE[2Pi, 1.0- a^2/b^2],20]
%      Out:= 48.442241102738385905
%
%   Mathematica Test 2:
%       In:= b = 10; a = 5;
%            SetPrecision[b*(EllipticE[Pi/2-Pi/10, 1.0- a^2/b^2]-EllipticE[Pi/10, 1.0- a^2/b^2]),20]
%      Out:= 7.3635807913930495516
%
%   MATLAB Test 1:
%       % full ellipse
%       arclength = arclength_ellipse(5,10)
%       arclength =
%           48.442241102738436
%
%   MATLAB Test 2:
%       % arclength ellipse
%       arclength = arclength_ellipse(5,10,pi/10,pi/2)
%       arclength =
%           7.363580791393055
%
%   References:
%   @see http://mathworld.wolfram.com/Ellipse.html
%   @see http://www.wolframalpha.com/input/?i=ellipse+arc+length&lk=1&a=ClashPrefs_*PlaneCurve.Ellipse.PlaneCurveProperty.ArcLength-
%

% Copyright Elliptic Project 2011
% For support, please reply to 
%     moiseev.igor[at]gmail.com
%     Moiseev Igor, 

%arguments
if nargin ~= 2 && nargin ~= 4,
 error('ARCLENGTH_ELLIPSE: Requires two or four inputs.')
 return
end

if nargin == 2,
 theta0 = 0;
 theta1 = 2*pi;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Comments inserted here to document this change; feel free to delete
%%% or modify them or move them to commit comments if you accept the
%%% pull request
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 2015-07-14 (New Horizons flyby of Pluto)
%%% drbitboy (Brian Carcich)
%%% 1) Old code returned values that were in error
%%% 1.1)  arclength_ellipse(1., .5, pi*.001, pi*.002) returned 0
%%% 1.2)  arclength_ellipse(1., .5, pi*.002, pi*.001) returned -.0003*pi instead of pi correct .0005*pi
%%% 1.3)  arclength_ellipse(1., .5, theta0, theta1) did not return the negative of the same call with the thetas reversed
%%% 2) Angles theta0 and theta1 were always interpreted as measured from the semi-minor axis
%%%
%%% 3) Corrected code:
%%% 3.1) Angle theta is measured from the positive a axis
%%% 3.2) The standard form of the b*E(phi,m) arc length integral has m = 1 - (a/b)^2
%%% 3.2.1) N.B. That only only works if b>a
%%% 3.3) If a>b, then an alternate formula is used:  a*E(PI/2 - phi, m') where m' = 1 - (b/a)^2
%%% 3.4) A few simple cases will show that the new code is correct
%%%        arclength_ellipse(1, .5, pi*.001, pi*.002) ~  pi*.0005
%%%        arclength_ellipse(1, .5, pi*.002, pi*.001) = -arclength(1, .5, pi*.001, pi*.002) ~ -pi*.0005
%%%        arclength_ellipse(1., 2., pi*.001, pi*.002) ~ pi*.002
%%%        arclength_ellipse(1, .5, pi/2 - pi*.002, pi/2 - pi*.001) ~ -pi*.001
%%%        arclength_ellipse(1, 2., pi/2 - pi*.002, pi/2 - pi*.001) ~ -pi*.001
%%%        etc.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Default solution for a==b (circles)
arclength = a.*(theta1-theta0);

%%% Ellipses (a<b or a>b)
if(a<b)
    %%% Theta measured from a axis = semi-MINOR axis
    %%% Use standard formulation for E(phi,m)
    [F1, E1] = elliptic12( theta1, 1 - (a./b).^2 );
    [F0, E0] = elliptic12( theta0, 1 - (a./b).^2 );
    arclength = b.*(E1 - E0);
elseif(a>b)   
    %%% Theta measured from a axis = semi-MAJOR axis
    %%% Standard formulation will not work ((1-(a/b)^2) < 0); instead use PI/2 - phi and b/a instead of a/b
    [F1, E1] = elliptic12( pi/2 - theta1, 1 - (b./a).^2 );
    [F0, E0] = elliptic12( pi/2 - theta0, 1 - (b./a).^2 );
    %%% d(PI/2 - phi)/dphi = -1, so reverse operands in this difference to flip sign:
    arclength = a.*(E0 - E1);
end

return;



function [F,E,Z] = elliptic12(u,m,tol)
% ELLIPTIC12 evaluates the value of the Incomplete Elliptic Integrals 
% of the First, Second Kind and Jacobi's Zeta Function.
%
%   [F,E,Z] = ELLIPTIC12(U,M,TOL) where U is a phase in radians, 0<M<1 is 
%   the module and TOL is the tolerance (optional). Default value for 
%   the tolerance is eps = 2.220e-16.
%
%   ELLIPTIC12 uses the method of the Arithmetic-Geometric Mean 
%   and Descending Landen Transformation described in [1] Ch. 17.6,
%   to determine the value of the Incomplete Elliptic Integrals 
%   of the First, Second Kind and Jacobi's Zeta Function [1], [2].
%
%       F(phi,m) = int(1/sqrt(1-m*sin(t)^2), t=0..phi);
%       E(phi,m) = int(sqrt(1-m*sin(t)^2), t=0..phi);
%       Z(phi,m) = E(u,m) - E(m)/K(m)*F(phi,m).
%
%   Tables generating code ([1], pp. 613-621):
%       [phi,alpha] = meshgrid(0:5:90, 0:2:90);                  % modulus and phase in degrees
%       [F,E,Z] = elliptic12(pi/180*phi, sin(pi/180*alpha).^2);  % values of integrals
%
%   See also ELLIPKE, ELLIPJ, ELLIPTIC12I, ELLIPTIC3, THETA, AGM.
%
%   References:
%   [1] M. Abramowitz and I.A. Stegun, "Handbook of Mathematical Functions", 
%       Dover Publications", 1965, Ch. 17.1 - 17.6 (by L.M. Milne-Thomson).
%   [2] D. F. Lawden, "Elliptic Functions and Applications"
%       Springer-Verlag, vol. 80, 1989

% Copyright Elliptic Project 2011
% For support, please reply to 
%     moiseev.igor[at]gmail.com
%     Moiseev Igor, 
%
% The code is optimized for ordered inputs produced by the functions 
% meshgrid, ndgrid. To obtain maximum performace (up to 30%) for singleton, 
% 1-dimensional and random arrays remark call of the function unique(.) 
% and edit further code. 

if nargin<3, tol = eps; end
if nargin<2, error('Not enough input arguments.'); end

if ~isreal(u) || ~isreal(m)
    error('Input arguments must be real. Use ELLIPTIC12i for complex arguments.');
end

if length(m)==1, m = m(ones(size(u))); end
if length(u)==1, u = u(ones(size(m))); end
if ~isequal(size(m),size(u)), error('U and M must be the same size.'); end

F = zeros(size(u)); 
E = F;              
Z = E;
m = m(:).';    % make a row vector
u = u(:).';

if any(m < 0) || any(m > 1), error('M must be in the range 0 <= M <= 1.'); end

I = uint32( find(m ~= 1 & m ~= 0) );
if ~isempty(I)
    [mu,J,K] = unique(m(I));   % extracts unique values from m
    K = uint32(K);
    mumax = length(mu);
    signU = sign(u(I));

    % pre-allocate space and augment if needed
	chunk = 7;
	a = zeros(chunk,mumax);
	c = a; 
	b = a;
	a(1,:) = ones(1,mumax);
	c(1,:) = sqrt(mu);
	b(1,:) = sqrt(1-mu);
	n = uint32( zeros(1,mumax) );
	i = 1;
	while any(abs(c(i,:)) > tol)                                    % Arithmetic-Geometric Mean of A, B and C
        i = i + 1;
        if i > size(a,1)
          a = [a; zeros(2,mumax)];
          b = [b; zeros(2,mumax)];
          c = [c; zeros(2,mumax)];
        end
        a(i,:) = 0.5 * (a(i-1,:) + b(i-1,:));
        b(i,:) = sqrt(a(i-1,:) .* b(i-1,:));
        c(i,:) = 0.5 * (a(i-1,:) - b(i-1,:));
        in = uint32( find((abs(c(i,:)) <= tol) & (abs(c(i-1,:)) > tol)) );
        if ~isempty(in)
          [mi,ni] = size(in);
          n(in) = ones(mi,ni)*(i-1);
        end
	end
     
    mmax = length(I);
	mn = double(max(n));
	phin = zeros(1,mmax);     C  = zeros(1,mmax);    
	Cp = C;  e  = uint32(C);  phin(:) = signU.*u(I);
	i = 0;   c2 = c.^2;
	while i < mn                                                    % Descending Landen Transformation 
        i = i + 1;
        in = uint32(find(n(K) > i));
        if ~isempty(in)     
            phin(in) = atan(b(i,K(in))./a(i,K(in)).*tan(phin(in))) + ...
                pi.*ceil(phin(in)/pi - 0.5) + phin(in);
            e(in) = 2.^(i-1) ;
            C(in) = C(in)  + double(e(in(1)))*c2(i,K(in));
            Cp(in)= Cp(in) + c(i+1,K(in)).*sin(phin(in));  
        end
	end
    
    Ff = phin ./ (a(mn,K).*double(e)*2);                                                      
    F(I) = Ff.*signU;                                               % Incomplete Ell. Int. of the First Kind
    Z(I) = Cp.*signU;                                               % Jacobi Zeta Function
    E(I) = (Cp + (1 - 1/2*C) .* Ff).*signU;                         % Incomplete Ell. Int. of the Second Kind
end

% Special cases: m == {0, 1}
m0 = find(m == 0);
if ~isempty(m0), F(m0) = u(m0); E(m0) = u(m0); Z(m0) = 0; end

m1 = find(m == 1);
um1 = abs(u(m1)); 
if ~isempty(m1), 
    N = floor( (um1+pi/2)/pi );  
    M = find(um1 < pi/2);              
    
    F(m1(M)) = log(tan(pi/4 + u(m1(M))/2));   
    F(m1(um1 >= pi/2)) = Inf.*sign(u(m1(um1 >= pi/2)));
    
    E(m1) = ((-1).^N .* sin(um1) + 2*N).*sign(u(m1)); 
    
    Z(m1) = (-1).^N .* sin(u(m1));                      
end
return;
