% Heat Project Code, Final -- Timothy Nickell -- SID#20469248 -- 12/03/13

% Changelog:

% Draft 1: I just got the spiral to render and changed sw s.t. it
% would adjust according to the maximum pixel density (length)--that is, as
% you change n.

% Draft 2: Corrected heat source to reflect temperature rate of change
% rather than temperature of the burner (which is much higher); that is, we
% don't want the bottom of the pan to gain 500K every second if the burner
% is only 500K--this doesn't make any sense--so instead we make the claim
% that the heat will transfer at, say, 1K per second.

% Draft 3: Made fixes, reentered source_temp for source temp, etc.

% Draft 4: Corrected diffusivity mistake, decreased time step to 0.003s.
% This makes the change required in Draft 2 make more sense: now, we can
% use a higher source temperature than 1K, but less than 500K (which makes
% no sense). Since Q is being scaled by dt, the number of iterations
% required for one second will yield an aggregate source temperature of Q.
% That is, if dt = 0.003 and the source term is dt*Q, then after 1000
% iterations we'll have 3 seconds and 3Q, so Q/second. Works!

% Draft 5: Updated Numit to 10000 --> 30 seconds; changed range to
% N-nn/sw/2

% Draft 6: Got rid of "close all" to  keep windows open; successfully
% consolidated two plots into one figure with subplot(); cleaned up unused
% code (formerly included in green).

% Draft 7: Finally inserted insulating boundary conditions/ got to work!
% Also: reduced Q-value (through source_temp) to better reflect final 
% temperature (Al melts at ~600 celsius, which we were well in excess of 
% after ~30 sec)

% Draft 8: Changed dt from 0.003 to 0.0025 and source_temp to 30; updated 
% numit in mod function below to update with simple change of Numit

% Draft 9: Changed Numit again (added 1 to end); changed source_temp to be
% lower; adjusted figure scale to 250 T-height; updated figure grapher with
% "set" function so that it would scale properly in graphing process

% Draft 10: changed T-height scale again, this time to 100; now only
% graphing to enough iterations s.t. total time = 15 seconds

%-----Start Code:-----

clear;
clf;

n=201;
sw=(n-1)/10; %spiral width

%--Source Term:--

A=zeros(n,n);
N=(n+1)/2; %midpoint
for i=1:n
    for j=1:n
        x0=N;
        y0=N;
        x=(i-x0);
        y=(j-y0);
        r=sqrt(x^2+y^2);
        if j >= N
            theta=acos(x/r);
        elseif j < N
            theta=acos(-x/r)+pi;
        end
        
        r1=theta/(2*pi)*sw;
        
        for k = 1:(N-1)/sw-1
            rr=r1+sw*(k-1);
            if r <= ceil(rr)+1 && r >= floor(rr)-1
                A(i,j)=1;
            end
        end
        
        %-----DON'T USE THESE ANYMORE, WE DON'T WANT A SOURCE AT THE EDGE
        %if r >= N-(nn)/sw && r <= N-(nn)/sw/2
        %    A(i,j)=1;
        %end
        %-----END
    end
end

%-----------------FORMER GRAPHING SCHEME:
%imagesc(A');
%set(gca,'YDir','normal');
%colormap(1-gray);
%axis equal;
%axis tight;
%-----------------END

Q = A; %Now we have our heat source equal to A

source_temp = 15;

for i=1:size(Q,1)
    for j=1:size(Q,2)
        if Q(i,j)==1
            Q(i,j)=source_temp;
        end
    end
end

f=0;

L=22; %bottom of pan = 22cm;
nn=n-1;

T_initial=zeros(n,n);
T_initial(:,:)=21;

dx = L/nn;
dy = L/nn;

T = T_initial;
%T=T+Q;

% to graph initial condition first (to check):
xx=0:dx:L;
yy=0:dy:L;
[X,Y]=meshgrid(xx,yy);
subplot(1,2,1);
    surf(X,Y,T);
    axis([0 L 0 L 0 100]);
    view([30 20]);
    title('Temperature (Vertical) with Time');
    xlabel('(cm)');
    ylabel('(cm)');
    zlabel('Temperature (deg. C)');
subplot(1,2,2);
    pcolor(X,Y,T);
    shading interp;
    hold on;
    contour(X,Y,T,30,'k');
    title('Contour Plot');
    xlabel('(cm)');
    ylabel('(cm)');
    hold off;
    
pause(5); % INITIAL PAUSE HERE

set(gcf,'PaperPositionMode','auto');
saveas(gcf,'projheat_000.png','png');

%--Now, on to the most exciting part: the heat flow:

Numit=6001;
Numpics=150;

% For the pan properties, we note that most pans are made of aluminum:

k = 2.37; % conductivity of aluminum; units of W/(cm*K) = J/(cm*s*K)
rho = 2.70; % density of aluminum; in units of g/cm^3
cp = 0.8969095605; % heat capacity of aluminum; in units of J/(g*K)

kappa=(k)/(rho*cp); 

kappa %print to check
dx %print to check
dy %print to check

dt = 0.0025; % the time step must be small here, otherwise eta will be too
             % large and the distribution will become unstable

for k=1:Numit
    Tnew = T;
    for i=2:nn
        for j=2:nn
            x0=N;
            y0=N;
            x=(i-x0);
            y=(j-y0);
            r=sqrt(x^2+y^2);
            if r <= N-nn/sw %nn/sw should always give 10; /2 = 5.
                Tnew(i,j)=dt*kappa*((T(i+1,j)-2*T(i,j)+T(i-1,j))/(dx^2)+...
                    (T(i,j+1)-2*T(i,j)+T(i,j-1))/(dy^2))+dt*Q(i,j)+T(i,j);
            end
            
            % Now for the hard part: (FULLY) INSULATING BOUNDARY CONDITIONS
            if N-nn/sw < r && r < N-nn/sw/2
                if i < N
                    if j < N
                        Tnew(i,j) = Tnew(i+1,j+1);
                    elseif j == N
                        Tnew(i,j) = Tnew(i+1,j);
                    else
                        Tnew(i,j) = Tnew(i+1,j-1);
                    end
                elseif i == N
                    if j < N
                        Tnew(i,j) = Tnew(i,j+1);
                    elseif j == N
                        Tnew(i,j) = Tnew(i,j);
                    else
                        Tnew(i,j) = Tnew(i,j-1);
                    end
                else
                    if j < N
                        Tnew(i,j) = Tnew(i-1,j+1);
                    elseif j == N
                        Tnew(i,j) = Tnew(i-1,j);
                    else
                        Tnew(i,j) = Tnew(i-1,j-1);
                    end
                end
            end
            %END  boundary conditions
            
        end
    end
    
    fprintf('%d iterations have been run.\n',k);
    T=Tnew;
    if mod(k+(Numit-1)/Numpics-1,(Numit-1)/Numpics) == 0 % Changed in Drafts 5,8
        f=f+1;
        %plot(x,T,'--rs','MarkerSize',10)
        xx=0:dx:L;
        yy=0:dy:L;
        [X,Y]=meshgrid(xx,yy);
        subplot(1,2,1);
            surf(X,Y,T);
            axis([0 L 0 L 0 100]);
            view([30 20]);
            title('Temperature (Vertical) with Time');
            xlabel('(cm)');
            ylabel('(cm)');
            zlabel('Temperature (deg. C)');
        subplot(1,2,2);
            pcolor(X,Y,T);
            shading interp;
            hold on;
            contour(X,Y,T,30,'k');
            title('Contour Plot');
            xlabel('(cm)');
            ylabel('(cm)');
            hold off;
        saveas(gcf,['projheat_',sprintf('%03d',f),'.png']);
        pause(0.05);
    end
end
