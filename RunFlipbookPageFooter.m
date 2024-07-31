%% Load blade data
% Loads the turbine blade planform. The input file has three columns, which
% specifiy the spanwise location, the chord length and the relative
% position of the pitch axis

sfileIn = 'turbinePlanform.dat';

sttmp = importdata(sfileIn,'\t',1);

d1z = sttmp.data(:,1);
d1c = sttmp.data(:,2);
d1pax = sttmp.data(:,3);

dR = d1z(end);
droot = d1z(1);

clear sfileIn sttmp

%% Input turbine plot
ip = 100; % Number of pages
ipSweepStart = 20; % Page at which the blades start sweeping
ipSweepFull = 80; % Page at which the blades reach maximum sweep
dsweepFull = -0.2; % Maximum sweep of the blade (non-dimensionalised by R)
ddaz = 5; % Delta azimuth per page
dh = 1.5; % Hub height

i1p = 0:ip; % Vector containing page counter
d1az = mod(i1p*ddaz,360); % Turbine azimuth for each page

d1towX = 0.04*[1 0.7 -0.7 -1]; % Tower geometry, tower top diameter to tower bottom diameter has a ratio of 0.7, 0.04 is an arbitrary scaling factor so that the tower look good in relation to blade geometry
d1towY = -dh*[1 0 0 1]; 

%% Create blade geometries with varying sweep
% Create two arrays that will contain the x and y coordinates of the
% blade's leading and trailing edge for each page
d2x = zeros(2*length(d1z),length(i1p));
d2y = zeros(2*length(d1z),length(i1p));

% Create a vector that defines the tip sweep extent for each page. For all
% page numbers smaller than ipSweepStart, the tip sweep extent is zero. For
% all pages larger than ipSweepFull, the tip sweep will be set to the
% maximum value. For all pages in between, a linear increase of the tip
% sweep is calculated.
d1sweepTip = zeros(1,length(i1p));
d1sweepTip(i1p >= ipSweepStart & i1p <= ipSweepFull) = -dsweepFull*((ipSweepStart:ipSweepFull) - ipSweepStart)/(ipSweepFull - ipSweepStart);
d1sweepTip(i1p > ipSweepFull) = -dsweepFull;

% Relative radial coordinate 
d1r = d1z/dR;

% This loop generates and stores the blade geometry coordinates for each
% page.
for i = 1:length(i1p)
    d1TE = -d1c.*d1pax;
    d1LE = d1c.*(1 - d1pax);

    dsweepStart = 0.5;
    dsweepTip = d1sweepTip(i);
    dsweepExp = 2;

    dscale = sqrt(1 + dsweepTip^2);
    d1rSweep = d1r/dscale;

    d1sweep = dsweepTip*((d1r - dsweepStart)/(1 - dsweepStart)).^dsweepExp;
    d1sweep(d1r < dsweepStart) = 0;

    d1Lambda = [0;atand(diff(d1sweep)./diff(d1rSweep))];

    d1LEx = d1rSweep*dR - d1LE.*sind(d1Lambda);
    d1LEy = d1sweep*dR + d1LE.*cosd(d1Lambda);

    d1TEx = d1rSweep*dR - d1TE.*sind(d1Lambda);
    d1TEy = d1sweep*dR + d1TE.*cosd(d1Lambda);

    d2x(:,i) = [d1LEx;flipud(d1TEx)];
    d2y(:,i) = [d1LEy;flipud(d1TEy)];
end

clear d1sweepTip d1r i d1TE d1LE dsweepStart dsweepTip dsweepExp dscale d1rSweep d1sweep d1Lambda d1LEx d1LEy d1TEx d1TEy

%% Create PDF with turbine plot on each page
% Output file name
sfileOut = 'FlipbookPageFooter.pdf';

% Delete file from previous run
delete(sfileOut);

% Set colour of turbine plot
d1TUDcyan = [0 166 214]/255;

% Create empty array that will contain the file names of each frame
ca1frames = cell.empty(0,length(i1p));

% Rotation matrix
frot = @(phi) [cosd(phi) sind(phi); -sind(phi) cosd(phi)];

% Initialise figure
d1pos = [488 342 423 420]; % Figure position on screen
figure
set(gcf,'Color','none'); % Set figure background to transparent
set(gcf,'Position',d1pos) % Set figure position on screen
set(gcf,'Units','centimeters'); % Set figure units to centimeters
d1posCM = get(gcf,'Position');
set(gcf,'PaperPositionMode','Auto','PaperUnits','centimeters','PaperSize',[d1posCM(3), d1posCM(4)]) % Set pdf properties
tiledlayout(1,1,'TileSpacing','none','Padding','tight') % Use tiledlayout to ensure axis reaches boundary of figure window
nexttile(1); hold on; daspect([1 1 1]); axis off;
set(gca,'Color','none') % Set axis background to transparent
xlim([-1.618*dR,dR]); ylim([-dh,dR]); % Set axis limits; xlim is set such that the turbine location splits the figure in the golden ratio

for i = 1:length(i1p)
    cla;
    % Plot tower
    patch(d1towX,d1towY,d1TUDcyan,'EdgeColor','none')
    % Plot hub
    scatter(0,0,200,d1TUDcyan,"filled",'MarkerEdgeColor','none')
    % Plot blade 1
    d2tmp = frot(d1az(i)-90)*[d2x(:,i),d2y(:,i)]';
    patch(d2tmp(1,:),d2tmp(2,:),d1TUDcyan,'EdgeColor','none')
    % Plot blade 2
    d2tmp = frot(d1az(i)+120-90)*[d2x(:,i),d2y(:,i)]';
    patch(d2tmp(1,:),d2tmp(2,:),d1TUDcyan,'EdgeColor','none')
    % Plot blade 3
    d2tmp = frot(d1az(i)-120-90)*[d2x(:,i),d2y(:,i)]';
    patch(d2tmp(1,:),d2tmp(2,:),d1TUDcyan,'EdgeColor','none')
    % Plot ground
    plot([-1.618*dR,dR],[-dh,-dh],'Color',d1TUDcyan,'LineWidth',1)
    
    % Save figure as pdf
    saveas(gcf,['frame',num2str(i,'%03i')],'pdf');
    % Store file name in an array
    ca1frames{i} = ['frame',num2str(i,'%03i'),'.pdf'];
end

% Use community function append_pdfs to append the pdfs of each individual
% frame to one pdf with one frame per page.
append_pdfs(sfileOut,ca1frames{:});
% Delete the individual frame pdf files
for i = 1:length(ca1frames)
    delete(ca1frames{i});
end
