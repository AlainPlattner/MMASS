function SPIE2009_1(ex)
% SPIE2009, Figure 3
%
% TOP: A rendition of the POMME-4 lithospheric magnetic field model
% bandpassed through degrees 17-72
% MIDDLE: A rendition of a localized version thereof, generated by
% multiplying the a partial expansion of POMME-4 to degree 36 by the
% first of a Slepian set bandlimited to 36. The effective bandwidth of
% the result is now also 72. 
% BOTTOM: The Slepian expansion of the above.
%
% Last modified by fjsimons-at-alum.mit.edu, 02/12/2011

% Coefficients and parameters
% Filtering of the input geomagnetic model
lmin=17;
lmax=72;
% Bandwidth of the Slepian window, half bandwidth of Slepian expansion
L=36;
% Geometry of the Slepian window over Africa
TH=18;
phi0=18;
theta0=85;
omega0=0;
% Calculate the circle with ofs degrees offset
ofs=10;
[lon2,lat2]=caploc([phi0+ofs 90-theta0],TH);

% Load the map and the coefficients
% Low-res first
d=POMME4([lmin lmax],0,1); size(d)
[~,lmcosip,degres]=POMME4([lmin lmax],0);

% Make the plot
[ah,ha,H]=krijetem(subnum(3,2));

% The full field
axes(ah(1)) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Note the new map trick based on full map expansion
c11cmn=[-169 90 191 -90];
[dr,lola]=maprotate(d,c11cmn);
imagefnan(c11cmn(1:2),c11cmn(3:4),setnans(dr,1000),kelicol,halverange(dr)); 
hold on; plot(lola(:,1),lola(:,2),'k'); 
plot(lon2-ofs,lat2)
hold off

% The full spherical harmonics
axes(ah(2)) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
imap=plm2map(lmcosip);
imagefnan([-lmax 0],[lmax lmax],setnans(imap,1000),kelicol,halverange(imap));
hold on
plot(0:2*L,0:2*L,'k')
plot(0:-1:-2*L,0:2*L,'k')
hold off
t(2)=title(sprintf('%i (%i) spherical harmonic coefficients',...
		   (lmax+1)^2-(lmin-1+1)^2,...
		   sum(~isnan(setnans(imap(:),1000)))));
movev(t(2),3)
xl(2)=xlabel('order m');
yl(2)=ylabel('degree l');

% The reduced field
axes(ah(3)) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Take the coefficients of the first Slepian function
Glm1=kindeks(glmalphapto(TH,L,phi0,theta0,omega0),1);
% Rearrange into the familiar format
[a1,a2,a3,lmcosi,a5,mzo,a7,a8,rinm,ronm]=addmon(L);
% Stick in the coefficients of the 1st eigentaper
cosi=lmcosi(:,3:4); cosi(ronm)=Glm1; lmcosi(:,3:4)=cosi;
% Construct the spatial taper to degree L
dt=plm2xyz(lmcosi,degres);
% Construct the spatial data to degree L
dL=plm2xyz(lmcosip(1:addmup(L)-addmup(lmin-1),:),degres);
% Taper the data
dtapered=dL.*dt;

% Plot the tapered data
dtaperedr=maprotate(dtapered,c11cmn);
imagefnan(c11cmn(1:2),c11cmn(3:4),setnans(dtaperedr,1000),...
	  kelicol,halverange(dtaperedr)); 
hold on; plot(lola(:,1),lola(:,2),'k'); 
plot(lon2-ofs,lat2)
hold off
axis([phi0-4*TH phi0+4*TH 90-(theta0+2*TH) 90-(theta0-2*TH)])

% The reduced field harmonics - by spherical harmonics
axes(ah(4)) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Since it's data at L tapered by window at L it's now 2L
lmcosit=xyz2plm(dtapered,2*L);
imap=plm2map(lmcosit);
imagefnan([-2*L 0],[2*L 2*L],setnans(imap,1000),kelicol,halverange(imap));
hold on
plot(0:2*L,0:2*L,'k')
plot(0:-1:-2*L,0:2*L,'k')
hold off
t(4)=title(sprintf('%i (%i) spherical harmonic coefficients',...
		   (2*L+1)^2,...
		   sum(~isnan(setnans(imap(:),1000)))));
movev(t(4),3)
xl(4)=xlabel('order m');
yl(4)=ylabel('degree l');

% Verify that this reconstruction now is awesome left and right
difer(dtapered-plm2xyz(lmcosit,degres),7);

% The reduced field harmonics - by Slepian functions
axes(ah(6)) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Calculate the corresponding Slepian expansion coefficients exactly
nosort=1;
[falpha,V,N,MTAP]=plm2slep(lmcosit,TH,2*L,phi0,theta0,omega0,nosort);

J=round(N);

% Arrange them in a pie shape
imap=slep2map(falpha,MTAP);
imagefnan([-2*L 0],[2*L 2*L],setnans(imap,1000),kelicol,halverange(imap))
hold on
plot(0:L,0:L,'k')
plot(0:-1:-L,0:L,'k')
hold off
set(ah(6),'xlim',[-L L],'ylim',[0 L])
t(6)=title(sprintf('%i (%i) Slepian coefficients',J,...
		   sum(~isnan(setnans(imap(:),1000)))));
movev(t(6),1.5)
xl(6)=xlabel('order m');
yl(6)=ylabel('rank + order \alpha + |m|');

% A re-expansion should be exact but we shall only do the partial
% expansion up to the Shannon number
theta=[theta0-2*TH:degres:theta0+2*TH];
phi=[phi0-4*TH:degres:phi0+4*TH];
c11cmn=[min(phi) 90-(theta0-2*TH) max(phi) 90-(theta0+2*TH)];

% Get the Slepian eigenfunctions, perhaps truncated to J n.e. (L+1)^2
fname=fullfile(getenv('IFILES'),'GLMALPHAPTO',...
	       sprintf('SPIE-%i-%i-%i-%i-%i.mat',...
		       TH,L,phi0,theta0,omega0));
if exist(fname)==2
  load(fname)
else
  [Gar,V]=galphapto(TH,2*L,phi0,theta0,omega0,theta/180*pi,phi/180*pi,J);
  save(fname,'Gar','V')
end

% Re-expand, but remember Gar is eigenvalue-sorted
[V,i]=sort(V,'descend');
falpha=falpha(i);

% Check the inverse transform just to be on the safe side
difer(lmcosit-slep2plm(falpha,TH,2*L,phi0,theta0,omega0));

% Using only restricted range, this would be SLEP2PLM wacth the factor
drexp=reshape(falpha(1:J)'*Gar,length(theta),length(phi))*sqrt(4*pi);

% The reduced field
axes(ah(5)) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
imagefnan(c11cmn(1:2),c11cmn(3:4),setnans(drexp,1000),kelicol,halverange(drexp));
hold on; plot(lola(:,1),lola(:,2),'k'); 
plot(lon2-ofs,lat2)
hold off
axis([phi0-4*TH phi0+4*TH 90-(theta0+2*TH) 90-(theta0-2*TH)])

% Compare the rms with the theory
% Make a very local-only expansion to calculate the mse in the region
c11cmnlocal=[phi0-TH 90-(theta0-TH) phi0+TH 90-(theta0+TH)];
dlocal=plm2xyz(lmcosit,degres,c11cmnlocal);
% Compare with a very-local-only expansion of the truncated Slepian basis
falpha2=falpha; falpha2(J+1:end)=0;
dslepJ=plm2xyz(slep2plm(falpha2,TH,2*L,phi0,theta0,omega0),degres,c11cmnlocal);
% Now get rid of all of the points which aren't even in the circle

% Later we will do this using SLEP2XYZ and watching the sqrt(4*pi)

% Note that the two above metrics should tend to one another only when
% the "observed" expansion is EXACTLY equal to the concentration region 
biglat=linspace(90-(theta0+TH),90-(theta0-TH),size(dlocal,1));
biglon=linspace(phi0-TH,phi0+TH,size(dlocal,2));
[Blon,Blat]=meshgrid(biglon,biglat);
imin=inpolygon(Blon,Blat,lon2-ofs,lat2);

% Get an idea of the faithfulness of the reconstruction, i.e. the
% R-averaged relative power of the reconstruction mean-square error
Rrmseobs=mean((dlocal(imin(:))-dslepJ(imin(:))).^2)./...
	     mean(dlocal(imin(:)).^2);
disp(sprintf('Observed relative error in percent %7.2e',100*Rrmseobs))
% Note that the bias in the region, per Slepian and also ourselves, is
% equal to the sum of the neglected Slepain coefficients, squared, times
% the eigenvalue, which we could calculate
Rrmsepred=sum(falpha(J+1:end).^2.*V(J+1:end)')/sum(falpha.^2.*V');
disp(sprintf('Predicted relative error in percent %7.2e',100*Rrmsepred))

t(5)=title(sprintf('R-average mse %7.2e%s',100*Rrmsepred,'%'));

% Cosmetics
fig2print(gcf,'tall')
longticks(ah,1.5)
set(ha(1),'xtick',[-120:60:180],'ytick',[-90:90:90])
set(ha(2:3),'xtick',[-50:25:75],'ytick',[-30:30:30])
set(ha(4:5),'xtick',[-2*L:2*18:2*L],'ytick',[0:2*18:2*L])
set(ha(6),'xtick',[-L:18:L],'ytick',[0:18:L])
deggies(ha(1:3))
serre(H',[],'down')
serre(H',1,'down')
[bh,th]=label(ah);
movev(ah,.1)
axes(ha(3))
[cb,xcb]=addcb([0.3 0.175 0.4 0.0175],...
	 halverange(drexp),halverange(drexp),'kelicol',...
	       range(halverange(drexp)/6),[]);
delete(xcb)
set(cb,'xtickl',{'-1/2 max(abs(value))',[],[],'0',[],[],'1/2 max(abs(value))'})

figdisp

defval('ex',0)
if ex~=0
  fig2print(gcf,'landscape')
  delete(th)
  delete(bh)
  switch ex
   case 1
    delete(ah(3:6))
    layout(ah(1:2)',0.4,'m','y') 
   case 2
    delete(ah([1:2 5 6]))
    layout(ah(3:4)',0.4,'m','y') 
   case 3
    delete(ah(1:4))
    layout(ah(5:6)',0.4,'m','y') 
  end
  figna=figdisp([],letter(ex),[],1);
  system(sprintf('degs %s.eps',figna));
  system(sprintf('epstopdf %s.eps',figna));
end
