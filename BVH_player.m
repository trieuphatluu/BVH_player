function BVH_player(varargin)
% v 1.0
% 2016/09/24
% Author: Phat Luu. tpluu2207@gmail.com
% Brain Machine Interface Lab
% University of Houston, TX, USA.
% ===================================================================
% Add Paths and external libs
uhlib = '..\uhlib';
addpath(genpath(uhlib));
% Import Java
import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import java.util.*;
import java.lang.*;
% DEFINES
handles.filekeyword = 'MODULE';
global gvar Dxyz;
gvar=def_gvar;
%====STEP 1: FRAME====
handles.iconlist=getmatlabicons;
% Create a new figure
[handles.figure, handles.jstatusbarhdl,handles.jwaitbarhdl]=uh_uiframe('figname',mfilename,...
    'units','norm','position',[0.1 0.1 0.8 0.8],...
    'toolbar','figure',...
    'statusbar',1, 'icon',handles.iconlist.uh,'logo','none',...
    'logopos',[0.89,0.79,0.2,0.2]);
% Frame-Title
% handles.text_title = uicontrol('Style','text', 'Units','norm', 'Position',[.2,.8,.6,.17],...
%     'FontSize',20, 'Background','w', 'Foreground','r',...
%     'String','BVH PLAYER');
%==============================UI CONTROL=================================
% Set Look and Feel
uisetlookandfeel('window');
% Warning off
warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
warning('off','MATLAB:uigridcontainer:MigratingFunction');
warning('off','MATLAB:uitree:MigratingFunction');
warning('off','MATLAB:uitreenode:DeprecatedFunction');
% combobox and List files
uistring={{''},icontext(handles.iconlist.action.updir,''),...
    '','',...
    };
w=0.4; h=0.35;
[container_filelist,handles.combobox_currdir, handles.pushbutton_updir,...
    handles.jlistbox_filenameinput,~,...
    ]=uigridcomp({'combobox','pushbutton',...
    'list','label',...
    },...
    'uistring',uistring,...
    'position',[gvar.margin.l 0.625 w h],...
    'gridsize',[2 2],'gridmargin',5,'hweight',[8.5 1.5],'vweight',[1.5 7.5]);
% Player
handles.player = axes;
handles.signalax = axes;
handles.signalannoax = axes;
handles.mapax = axes;
% Player control button
uistring={icontext(handles.iconlist.action.play,'Start'),...
    '',...
    '',...
    'Default View',...
    };
[container_controller,...
    handles.pushbutton_play,handles.slider_frame,...
    handles.edit_frame,handles.checkbox_defaultview]=uigridcomp({'pushbutton','slider','edit','checkbox'},...
    'uistring',uistring,...
    'gridsize',[1 4],'gridmargin',10,...
    'hweight',[1 6.5 1.2 1.3],'vweight',1);
% Gait event information
uistring={'Import GC',...
    icontext(handles.iconlist.walk,''),...    
    '','','','','',...    
    {'LW0F','RD','LW1F','LW2F','LW3F','SA','LW4F',...
    'LW4B','SD','LW3B','LW2B','LW1B','RA','LW0B'},...
    icontext(handles.iconlist.action.import,'Insert'),...
    icontext(handles.iconlist.action.update,'Update')};
[container_gcevent,...
    handles.checkbox_importgc,~,handles.edit_gcevent1,handles.edit_gcevent2,handles.edit_gcevent3,...    
    handles.edit_gcevent4,handles.edit_gcevent5,...
    handles.combobox_gclabel,...
    handles.pushbutton_insert,handles.pushbutton_update]=uigridcomp({
    'checkbox','label','edit','edit','edit','edit','edit',...
    'combobox',...
    'pushbutton','pushbutton'},...
    'uistring',uistring,...
    'gridsize',[1 10],'gridmargin',8,...
    'hweight',[1.5 0.5, 1 1 1 1 1, 1 1.2 1.2],'vweight',1);

% List box to display current GC data;
uistring={'',...
    };
[container_matdata,handles.jlistbox_matdata,...    
    ]=uigridcomp({'list',...
    },...
    'uistring',uistring,...    
    'gridsize',[1 1],'gridmargin',5);
% Save matdata
uistring={icontext(handles.iconlist.arrowup,'Move'),...
    icontext(handles.iconlist.arrowdown,'Move'),...
    icontext(handles.iconlist.action.delete,'Del'),...
    '',...
    icontext(handles.iconlist.action.save,'Save'),...
    };
[container_save,handles.pushbutton_moveup,handles.pushbutton_movedown,handles.pushbutton_del,~,handles.pushbutton_save,...    
    ]=uigridcomp({'pushbutton','pushbutton','pushbutton','label',...
    'pushbutton'},...
    'uistring',uistring,...    
    'gridsize',[1 5],'gridmargin',5,'hweight',[1.5 1.5 1.5 3.5 2]);
% Option to select the landed leg before transition (LW-SA, SA-LW, LW-SD, SD-LW)
titlename = {'LW-SA1','SA-LW1','LW-SD1','SD-LW1',...
    'LW-SA2','SA-LW2','LW-SD2','SD-LW2'};
for i = 1 : length(titlename)
    handles.radio_transleg(i) = uh_uiradiobutton('title',titlename{i},...
        'string',{icontext(handles.iconlist.leftfoot,'L'),icontext(handles.iconlist.rightfoot,'R')},...
        'fontsize',8);
    groupobj(i) = handles.radio_transleg(i).group;
end
uipanel_radio = uipanellist('title','Transition Foot',...
                'objects',groupobj,...
                'itemwidth',0.1,'itemheight',0.9,'align','horizontal',...
                'marginleft',gvar.margin.gap*3,...
                'gap',[gvar.margin.gap*2 0]); 
% TIMER OBJECT
handles.mytimer = timer('ExecutionMode','fixedSpacing',...
    'Period',0.01,...
    'BusyMode','drop',...
    'TimerFcn',{@timerFcn_Callback,handles},...
    'StopFcn',{@timerStopFcn_Callback,handles});
% Alignment
uialign(handles.player,container_filelist,'align','east','scale',[1.3 1.25],'gap',[0.06 -0.23]);
uialign(handles.signalax,container_filelist,'align','east','scale',[1.3 0.6],'gap',[0.06 0.0]);
uialign(container_controller,handles.player,'align','southwest','scale',[1 0.12],'gap',[0 -0.01]);
uialign(container_gcevent,container_controller,'align','southwest','scale',[1 1],'gap',[0 -0.01]);
uialign(container_matdata,container_filelist,'align','southwest','scale',[0.85 1.4],'gap',[0 -0.01]);
uialign(container_save,container_matdata,'align','southwest','scale',[1 0.1],'gap',[0 -0.01]);
uialign(uipanel_radio,container_gcevent,'align','southwest','scale',[1 2.5],'gap',[0 -0.01]);
set(handles.signalannoax,'position',get(handles.signalax,'position'));
uialign(handles.mapax,handles.player,'align','west','scale',[0.35 0.8],'gap',[0.13 0]);
% Initialize
uisetjcombolist(handles.combobox_currdir,{cd});
uijlist_setfiles(handles.jlistbox_filenameinput,cd);
handles.currframe = 1 ; % to store current frame of timer object
set(handles.combobox_gclabel,'SelectedIndex',0,'MaximumRowCount',10);
set(handles.slider_frame,'min',0,'max',10000);
handles.keyholder = '';
set(handles.checkbox_defaultview,'value',1);
set(handles.signalax,'color','none');
set(handles.mapax,'color','none');
uistack(handles.signalannoax,'top');
uistack(handles.mapax,'top');

% Setappdata
setappdata(handles.figure,'handles',handles);
% set(handles.combobox_gclabel,'background',javax.swing.plaf.ColorUIResource([256 0 0]))
%====STEP 4: DEFINE CALLBACK====
% Combobox
set(handles.combobox_currdir,'ActionPerformedCallback',{@combobox_currdir_Callback,handles});
% Checkbox
set(handles.checkbox_defaultview,'Callback',{@checkbox_defaultview_Callback,handles});
set(handles.checkbox_importgc,'Callback',{@checkbox_importgc_Callback,handles});
% Keyboard control
set(handles.figure,'WindowKeyPressFcn',{@KeyboardThread_Callback,handles});
set(handles.jlistbox_filenameinput,'KeyPressedCallback',{@KeyboardThread_Callback,handles});
set(handles.jlistbox_matdata,'KeyPressedCallback',{@KeyboardThread_Callback,handles});
% Mouse control
set(handles.jlistbox_filenameinput,'MousePressedCallback',{@jlistbox_filenameinput_Mouse_Callback,handles});
% listbox
set(handles.jlistbox_matdata,'MousePressedCallback',{@jlistbox_matdata_Callback,handles});
% Pushbutton
set(handles.pushbutton_updir,'Callback',{@pushbutton_updir_Callback,handles});
set(handles.pushbutton_play,'Callback',{@pushbutton_play_Callback,handles});
set(handles.pushbutton_save,'Callback',{@pushbutton_save_Callback,handles});
set(handles.pushbutton_del,'Callback',{@pushbutton_del_Callback,handles});
set(handles.pushbutton_insert,'Callback',{@pushbutton_insert_Callback,handles});
set(handles.pushbutton_update,'Callback',{@pushbutton_update_Callback,handles});
set(handles.pushbutton_moveup,'Callback',{@pushbutton_moveup_Callback,handles});
set(handles.pushbutton_movedown,'Callback',{@pushbutton_movedown_Callback,handles});
% Slider and edit text
set(handles.edit_frame,'Callback',{@edit_frame_Callback,handles});
set(handles.slider_frame,'Callback',{@slider_frame_Callback,handles});

% CALLBACK

function checkbox_defaultview_Callback(hObject,eventdata,handles)
handles=getappdata(handles.figure,'handles');
val = get(hObject,'value');
if val == 1
    axes(handles.player);
    view([0 0]);
end
% Setappdata
setappdata(handles.figure,'handles',handles);

function jlistbox_filenameinput_Mouse_Callback(hObject,eventdata,handles)
handles=getappdata(handles.figure,'handles');
eventinf=get(eventdata);
if eventinf.Button==1 && eventinf.ClickCount==2 %double left click
    handles = jlistbox_filenameinput_load(hObject,handles);
elseif eventinf.Button==3       %Right Click
    handles.jmenu.show(hObject,eventinf.X,eventinf.Y);
    handles.itempos.x=eventinf.X;
    handles.itempos.y=eventinf.Y;
end
% Setappdata
setappdata(handles.figure,'handles',handles);

function handles = jlistbox_filenameinput_load(hObject,handles);
handles=getappdata(handles.figure,'handles');
[stacktrace, ~]=dbstack;
thisFuncName=stacktrace(1).name;
%=====
val=get(hObject,'SelectedValue');
mark1=strfind(val,'>');mark1=mark1(end-1);
mark2=strfind(val,'<');mark2=mark2(end);
filename=val(mark1+1:mark2-1);
[~,selname,ext]=fileparts(filename);
currdir=get(handles.combobox_currdir,'selecteditem');
if isempty(ext)     %folder selection
    if strcmpi(currdir(end),'\')
        newdir=strcat(currdir,selname);
    else
        newdir=strcat(currdir,'\',selname);
    end
    uijlist_setfiles(handles.jlistbox_filenameinput,newdir,'type',{'.all'});
    handles.combobox_currdir.insertItemAt(newdir,0);
    set(handles.combobox_currdir,'selectedindex',0);
elseif strcmpi(ext,'.m')
    edit(fullfile(currdir,filename));
elseif strcmpi(ext,'.mat')
    fprintf('Load: %s.\n',filename);
    myfile = class_FileIO('filename',filename,'filedir',currdir);
    myfile.loadtows;
    handles.kinfile = myfile;
    kin = evalin('base','kin');            
    uisetjlistbox(handles.jlistbox_matdata,gcinfo2list(kin.gc.index,kin.gc.label));
    for i = 1 : length(kin.gc.transleg)
        if strcmpi(kin.gc.transleg(i),'l'), idx = 1;
        else idx = 2; end
        set(handles.radio_transleg(i).group,'selectedobject',handles.radio_transleg(i).items{idx});
    end
    set(handles.jlistbox_matdata,'SelectedIndex',0);
    updateSignalplot(handles);
    anno_signalax(handles);
    jlistbox_matdata_Callback(handles.jlistbox_matdata,[],handles);
elseif strcmpi(ext,'.bvh')
    [skeleton,time] = loadbvh(fullfile(currdir,filename));
    set(handles.slider_frame,'min',0,'max',length(time),...
        'sliderstep',[1 10]./length(time));
    for i = 1: length(skeleton)
        thisbody = skeleton(i).Dxyz;
        parent(i) = skeleton(i).parent;
        for j = 1 : length(time)
            Dxyz(:,i,j) = thisbody(:,j);
        end
    end    
    assignin('base','Dxyz',Dxyz);
    assignin('base','parent',parent);
    assignin('base','skeleton',skeleton);
    showframe(1,handles);    
    fprintf('bvh file is loaded.\n');
else
end
fprintf('DONE...%s.\n',thisFuncName);
% Setappdata
setappdata(handles.figure,'handles',handles);

function slider_frame_Callback(hObject,eventdata,handles)
handles=getappdata(handles.figure,'handles');
sl_val = round(get(hObject,'value'));
if sl_val ==0, sl_val = 1; end;
set(handles.edit_frame,'string',num2str(sl_val));
% UPdate jlistbox_matdata
gcinfo = gclist2info(uigetjlistbox(handles.jlistbox_matdata,'select','all'));
gcid = find(gcinfo.index(:,1) <= sl_val,1,'last');
% if isempty(gcid) 
%     setval = 0;
% elseif gcid >= size(gcinfo.index,1), setval = size(gcinfo.index,1)-1;
% else
%     setval = gcid-1;
% end
% set(handles.jlistbox_matdata,'SelectedIndex',setval);
if uh_isvarexist('skeleton')
    showframe(sl_val,handles);
end
% Scroll signal plot axis
axes(handles.signalax);
frameshow = 100;
if sl_val < frameshow,  tsignal = 1 : frameshow;
else tsignal = sl_val-frameshow : sl_val+frameshow; % Get 100 frames around current frame
end
set(gca,'xlim',[tsignal(1) tsignal(end)],'ylim',[-100 50]);
setappdata(handles.figure,'handles',handles);

function updateSignalplot(handles)
sl_val = round(get(handles.slider_frame,'value'));
gcinfo = gclist2info(uigetjlistbox(handles.jlistbox_matdata,'select','all'));

axes(handles.signalax);
cla; hold on;
frameshow = 100;
if sl_val < frameshow,  tsignal = 1 : frameshow;
else tsignal = sl_val-frameshow : sl_val+frameshow; % Get 100 frames around current frame
end
kin = evalin('base','kin');
AccLeftFoot = kin.Data.sensorAcceleration.LeftFoot(:,3);
AccRightFoot = kin.Data.sensorAcceleration.RightFoot(:,3);
OriLeftFoot = kin.Data.sensorOrientationEuler.LeftFoot(:,2);
OriRightFoot = kin.Data.sensorOrientationEuler.RightFoot(:,2);
PosLeftFoot = kin.Data.position.LeftFoot(:,3);
PosRightFoot = kin.Data.position.RightFoot(:,3);

plot(2*(AccRightFoot-mean(AccRightFoot))+15,'r');
plot(0.5*(OriRightFoot-mean(OriRightFoot))+15,'r.');
plot(2*(AccLeftFoot-mean(AccLeftFoot))+5,'k');
plot(0.5*(OriLeftFoot-mean(OriLeftFoot))+5,'k.');

plot(100*(PosRightFoot-mean(PosRightFoot))-50,'r-.');
plot(0.5*(OriRightFoot-mean(OriRightFoot))-50,'r.');
plot(100*(PosLeftFoot-mean(PosLeftFoot))-60,'k-.');
plot(0.5*(OriLeftFoot-mean(OriLeftFoot))-60,'k.');

selcolor = [255 0 0; 154 154 154; 0 0 0; 255 109 182]./256;
set(gca,'xlim',[tsignal(1) tsignal(end)],'ylim',[-100 50]);
for i = 1 : size(gcinfo.index,1)
    for j = 1 : size(gcinfo.index,2)-1
        if any(j == [1,3]), lwidth = 1;
        else lwidth = 0.5; end
        line('xdata',gcinfo.index(i,j).*[1 1],'ydata',get(gca,'ylim'),'color',selcolor(j,:),...
            'linewidth',lwidth,'linestyle','-.');
    end
end

function anno_signalax(handles)
axes(handles.signalannoax);
% Anno
axis off; hold on;
limx = [0 100]; limy = [-100 50];
set(gca,'xlim', limx,'ylim',limy);

selcolor = [255 0 0; 154 154 154; 0 0 0; 255 109 182]./256;
hdl = class_line('xdata',mean(limx).*[1 1],'ydata',[1.1*limy(2), limy(1)],...
    'linecolor','g');
set(hdl.textobj,'position',hdl.startpoint.position,'string','Current Frame',...
    'verticalalignment','bottom','horizontalalignment','center','fontsize',8,...
    'fontweight','bold','textgap',[0 0]);
hdl.drawshape;
% class_text('location','north','string','Current Frame','textgap',[0 5],'show',1);
% class_line('xdata',50,'ydata',52,'marker','v','markersize',15,'markerfacecolor','r','show',1);

% ====Anno for signals
limx = get(gca,'xlim');limy = get(gca,'ylim');
hdl = class_line('xdata',[limx(1) limx(1)+3],'ydata',(limy(1)-40).*[1 1],'linecolor','r');
set(hdl.textobj,'position',hdl.endpoint.position,'string','Acc-RightFoot',...
    'verticalalignment','middle','horizontalalignment','left','fontsize',8);
hdl.drawshape;
hdl = class_line('xdata',[limx(1) limx(1)+3],'ydata',(limy(1)-70).*[1 1],'linecolor','k');
set(hdl.textobj,'position',hdl.endpoint.position,'string','Acc-LeftFoot',...
    'verticalalignment','middle','horizontalalignment','left','fontsize',8);
hdl.drawshape;
%--
hdl = class_line('xdata',[limx(1)+12 limx(1)+15],'ydata',(limy(1)-40).*[1 1],'linecolor','r','linestyle',':');
set(hdl.textobj,'position',hdl.endpoint.position,'string','Orient-RightFoot',...
    'verticalalignment','middle','horizontalalignment','left','fontsize',8);
hdl.drawshape;
hdl = class_line('xdata',[limx(1)+12 limx(1)+15],'ydata',(limy(1)-70).*[1 1],'linecolor','k','linestyle',':');
set(hdl.textobj,'position',hdl.endpoint.position,'string','Orient-LeftFoot',...
    'verticalalignment','middle','horizontalalignment','left','fontsize',8);
hdl.drawshape;
%--
hdl = class_line('xdata',[limx(1)+27 limx(1)+30],'ydata',(limy(1)-40).*[1 1],'linecolor','r','linestyle','-.');
set(hdl.textobj,'position',hdl.endpoint.position,'string','Pos-RightFoot',...
    'verticalalignment','middle','horizontalalignment','left','fontsize',8);
hdl.drawshape;
hdl = class_line('xdata',[limx(1)+27 limx(1)+30],'ydata',(limy(1)-70).*[1 1],'linecolor','k','linestyle','-.');
set(hdl.textobj,'position',hdl.endpoint.position,'string','Pos-LeftFoot',...
    'verticalalignment','middle','horizontalalignment','left','fontsize',8);
hdl.drawshape;

% Anno for Features;
class_text('position',[limx(1)-7,40],'string',sprintf('Features\nLW'),'fontweight','bold','horizontalalignment','center','show',1);
class_text('position',[limx(1)-7,-50],'string',sprintf('Features\nSTAIR'),'fontweight','bold','horizontalalignment','center','show',1);
% Annotation for Gait Event;
hdl = class_line('xdata',(limx(2)-30).*[1 1],'ydata',[limy(1)-70, limy(1)-40],...
    'linecolor',selcolor(1,:),'linestyle','-.','linewidth',1);
set(hdl.textobj,'position',hdl.center.position,'string','RHC',...
    'verticalalignment','middle','horizontalalignment','left','fontsize',8,'textgap',[1 0]);
hdl.drawshape;
hdl = class_line('xdata',(limx(2)-22).*[1 1],'ydata',[limy(1)-70, limy(1)-40],...
    'linecolor',selcolor(2,:),'linestyle','-.');
set(hdl.textobj,'position',hdl.center.position,'string','LTO',...
    'verticalalignment','middle','horizontalalignment','left','fontsize',8,'textgap',[1 0]);
hdl.drawshape;
hdl = class_line('xdata',(limx(2)-14).*[1 1],'ydata',[limy(1)-70, limy(1)-40],...
    'linecolor',selcolor(3,:),'linestyle','-.','linewidth',1);
set(hdl.textobj,'position',hdl.center.position,'string','LHC',...
    'verticalalignment','middle','horizontalalignment','left','fontsize',8,'textgap',[1 0]);
hdl.drawshape;
hdl = class_line('xdata',(limx(2)-6).*[1 1],'ydata',[limy(1)-70, limy(1)-40],...
    'linecolor',selcolor(4,:),'linestyle','-.');
set(hdl.textobj,'position',hdl.center.position,'string','RTO',...
    'verticalalignment','middle','horizontalalignment','left','fontsize',8,'textgap',[1 0]);
hdl.drawshape;
set(gca,'xlim', limx,'ylim',limy);


function edit_frame_Callback(hObject,eventdata,handles)
handles=getappdata(handles.figure,'handles');
ed_str = get(hObject,'string');
set(handles.slider_frame,'value',str2num(ed_str));
slider_frame_Callback(handles.slider_frame,[],handles)
% Setappdata
setappdata(handles.figure,'handles',handles);

function checkbox_importgc_Callback(hObject,eventdata,handles)
handles=getappdata(handles.figure,'handles');
% Setappdata
if get(hObject,'value') == 1
    thisstr = uigetjlistbox(handles.jlistbox_matdata);
    gcinfo = gclist2info(thisstr);
    updateuigcevent(gcinfo,handles);
end
setappdata(handles.figure,'handles',handles);

function jlistbox_matdata_Callback(hObject,eventdata,handles)
handles=getappdata(handles.figure,'handles');
thisstr = uigetjlistbox(hObject);
gcinfo = gclist2info(thisstr);
if get(handles.checkbox_importgc,'value') == 1
    updateuigcevent(gcinfo,handles);
end
set(handles.edit_frame,'string',num2str(gcinfo.index(1)));
set(handles.slider_frame,'value',gcinfo.index(1));
slider_frame_Callback(handles.slider_frame,[],handles);
setappdata(handles.figure,'handles',handles);

function updateuigcevent(gcinfo,handles)
handles=getappdata(handles.figure,'handles');
if strcmpi(gcinfo.label,'LW0F'), idx = 0;
elseif strcmpi(gcinfo.label,'RD'), idx = 1;
elseif strcmpi(gcinfo.label,'LW1F'), idx = 2;
elseif strcmpi(gcinfo.label,'LW2F'), idx = 3;
elseif strcmpi(gcinfo.label,'LW3F'), idx = 4;
elseif strcmpi(gcinfo.label,'SA'), idx = 5;
elseif strcmpi(gcinfo.label,'LW4F'), idx = 6;
elseif strcmpi(gcinfo.label,'LW4B'), idx = 7;
elseif strcmpi(gcinfo.label,'SD'), idx = 8;
elseif strcmpi(gcinfo.label,'LW3B'), idx = 9;
elseif strcmpi(gcinfo.label,'LW2B'), idx = 10;
elseif strcmpi(gcinfo.label,'LW1B'), idx = 11;
elseif strcmpi(gcinfo.label,'RA'), idx = 12;
elseif strcmpi(gcinfo.label,'LW0B'), idx = 13;
else idx = 0;
end
set(handles.edit_gcevent1,'string',num2str(gcinfo.index(1)));
set(handles.edit_gcevent2,'string',num2str(gcinfo.index(2)));
set(handles.edit_gcevent3,'string',num2str(gcinfo.index(3)));
set(handles.edit_gcevent4,'string',num2str(gcinfo.index(4)));
set(handles.edit_gcevent5,'string',num2str(gcinfo.index(5)));
set(handles.combobox_gclabel,'selectedindex',idx);
% Setappdata
setappdata(handles.figure,'handles',handles);

function pushbutton_play_Callback(hObject,eventdata,handles)
handles=getappdata(handles.figure,'handles');
thisstr = get(hObject,'string');
if strcmpi(thisstr,icontext(handles.iconlist.action.play,'start'))
    set(hObject,'string',icontext(handles.iconlist.status.stop,'stop'));
    start(handles.mytimer);
else    
    stop(handles.mytimer); % Perform a list of task to quit the program
    set(hObject,'string',icontext(handles.iconlist.action.play,'start'));
end
% Setappdata
setappdata(handles.figure,'handles',handles);

function pushbutton_insert_Callback(hObject,eventdata,handles)
handles=getappdata(handles.figure,'handles');
gclabel = get(handles.combobox_gclabel,'selecteditem');
gcindex = get(handles.jlistbox_matdata,'SelectedIndex') + 1;
currlist = uigetjlistbox(handles.jlistbox_matdata,'select','all');
gcinfo = gclist2info(currlist);
insertval = [str2num(get(handles.edit_gcevent1,'string')),...
    str2num(get(handles.edit_gcevent2,'string')),...
    str2num(get(handles.edit_gcevent3,'string')),...
    str2num(get(handles.edit_gcevent4,'string')),...
    str2num(get(handles.edit_gcevent5,'string'))];
% Update GUI;
model=get(handles.jlistbox_matdata,'Model');
newitem = gcinfo2list(insertval,gclabel);
model.insertElementAt(newitem{1},gcindex);
set(handles.jlistbox_matdata,'selectedIndex',gcindex);
updateSignalplot(handles);
acc_color = [154 154 154]./256;
set(handles.edit_gcevent1,'backgroundcolor',acc_color);
set(handles.edit_gcevent1,'string',get(handles.edit_gcevent5,'string'));
for i = 2 : 5
    strcmd = sprintf('set(handles.edit_gcevent%d,''backgroundcolor'',''w'')',i);
    eval(strcmd);
    strcmd = sprintf('set(handles.edit_gcevent%d,''string'',''0'')',i);
    eval(strcmd);
end
set(handles.edit_gcevent2,'backgroundcolor','w');
set(handles.edit_gcevent3,'backgroundcolor','w');
set(handles.edit_gcevent4,'backgroundcolor','w');
set(handles.edit_gcevent5,'backgroundcolor','w');
% Setappdata
setappdata(handles.figure,'handles',handles);

function pushbutton_update_Callback(hObject,eventdata,handles)
handles=getappdata(handles.figure,'handles');
gclabel = get(handles.combobox_gclabel,'selecteditem');
gcindex = get(handles.jlistbox_matdata,'SelectedIndex') + 1;
currgclist = uigetjlistbox(handles.jlistbox_matdata,'select','all');
gcinfo = gclist2info(currgclist);
event = [str2num(get(handles.edit_gcevent1,'string')),...
    str2num(get(handles.edit_gcevent2,'string')),...
    str2num(get(handles.edit_gcevent3,'string')),...
    str2num(get(handles.edit_gcevent4,'string')),...
    str2num(get(handles.edit_gcevent5,'string'))];
newgcdata = gcinfo.index; newgcdata(gcindex,:) = event;
newgclabel = gcinfo.label; newgclabel{gcindex} = gclabel;
% Update GUI;
uisetjlistbox(handles.jlistbox_matdata,gcinfo2list(newgcdata,newgclabel));
set(handles.jlistbox_matdata,'selectedIndex',gcindex-1);
set(handles.edit_gcevent1,'backgroundcolor','w');
set(handles.edit_gcevent2,'backgroundcolor','w');
set(handles.edit_gcevent3,'backgroundcolor','w');
set(handles.edit_gcevent4,'backgroundcolor','w');
set(handles.edit_gcevent5,'backgroundcolor','w');
updateSignalplot(handles)
% Setappdata
setappdata(handles.figure,'handles',handles);

function pushbutton_del_Callback(hObject,eventdata,handles)
handles=getappdata(handles.figure,'handles');
% currgclist = uigetjlistbox(handles.jlistbox_matdata,'select','all');
% gcinfo = gclist2info(currgclist);
% try
%     gcinfo.index(gcindex,:) = [];
%     gcinfo.label(gcindex) = [];
% catch
% end
% uisetjlistbox(handles.jlistbox_matdata,gcinfo2list(gcinfo.index,gcinfo.label));
gcindex = get(handles.jlistbox_matdata,'SelectedIndex');
% Update GUI;
model=get(handles.jlistbox_matdata,'Model');
% methodsview(model)
% newitem = gcinfo2list(insertval,gclabel);
model.removeElementAt(gcindex);
% 
% set(handles.jlistbox_matdata,'selectedIndex',gcindex-1);
% updateSignalplot(handles)

% Setappdata
setappdata(handles.figure,'handles',handles);

function pushbutton_save_Callback(hObject,eventdata,handles)
handles=getappdata(handles.figure,'handles');
[stacktrace, ~]=dbstack;
thisFuncName=stacktrace(1).name;
for i = 1 : length(handles.radio_transleg)
if get(handles.radio_transleg(i).group,'selectedobject')==handles.radio_transleg(i).items{1}
    transleg(i)=cellstr('L'); else transleg(i)=cellstr('R'); end;
end
% Convert back to mat data from list data;
kin = evalin('base','kin');
kin.gc.transleg = transleg;
gcinfo = gclist2info(uigetjlistbox(handles.jlistbox_matdata,'select','all'));
kin.gc.index = gcinfo.index;
kin.gc.label = gcinfo.label;
kin.gc.time = (gcinfo.index-1)./60;
% kin.gc.index = kin.gc.event.index; % To modify kin format.
% kin.gc.time = kin.gc.event.time;
% kin.gc = rmfield(kin.gc,'event');
% kin.gc.transleg = transleg;
fprintf('Saving...%s\n',handles.kinfile.filename);
handles.kinfile.savevars(kin);
fprintf('DONE...%s\n',thisFuncName);
% Setappdata
setappdata(handles.figure,'handles',handles);

function pushbutton_moveup_Callback(hObject,eventdata,handles)
handles=getappdata(handles.figure,'handles');
selrow = get(handles.jlistbox_matdata,'selectedIndex');
model=get(handles.jlistbox_matdata,'Model');
insertitem = model.getElementAt(selrow);
model.insertElementAt(insertitem,selrow-1);
model.removeElementAt(get(handles.jlistbox_matdata,'selectedIndex'));
set(handles.jlistbox_matdata,'selectedIndex',selrow-1);
% Setappdata
setappdata(handles.figure,'handles',handles);

function pushbutton_movedown_Callback(hObject,eventdata,handles)
handles=getappdata(handles.figure,'handles');
selrow = get(handles.jlistbox_matdata,'selectedIndex');
model=get(handles.jlistbox_matdata,'Model');
insertitem = model.getElementAt(selrow);
model.insertElementAt(insertitem,selrow+2);
model.removeElementAt(get(handles.jlistbox_matdata,'selectedIndex'));
set(handles.jlistbox_matdata,'selectedIndex',selrow+1);
% Setappdata
setappdata(handles.figure,'handles',handles);

function showframe(ff,handles)
axes(handles.player); 
cla;hold on;
Dxyz = evalin('base','Dxyz');
parent = evalin('base','parent');

body = 1 : size(Dxyz,2);
body([8,13,18]) = []; % Remove unneccessary parts.
% 170703: Modify to Xsens updated software.
% The Dxyz variable in the skeleton change
% sequence. 
%  first row and third row have been switched/
% Z direction now includes height but drifts very
% much
xrow = 1; % v2.0
yrow = 3;
zrow = 2;
% plot3(Dxyz(1,body,ff),Dxyz(3,body,ff),Dxyz(2,body,ff),'.','markersize',20,...
%     'color',[154 154 154]./256);
plot3(Dxyz(xrow,body,ff),Dxyz(yrow,body,ff),Dxyz(zrow,body,ff),'.','markersize',20,...
    'color',[154 154 154]./256);
for i = 1 : length(body)
    nn = body(i);
    if any(nn==[19 20 21 22 23]), selcolor = 'r';
    elseif any(nn==[24 25 26 27 28]), selcolor = 'k';
    else selcolor = [154 154 154]./256;
    end
    thisparent = parent(nn);
    if thisparent > 0
        plot3([Dxyz(xrow,thisparent,ff) Dxyz(xrow,nn,ff)],...
            [Dxyz(yrow,thisparent,ff) Dxyz(yrow,nn,ff)],...
            [Dxyz(zrow,thisparent,ff) Dxyz(zrow,nn,ff)],...
            'color',selcolor);
    end
end
rtoe = [Dxyz(xrow,23,ff),Dxyz(yrow,23,ff), Dxyz(zrow,23,ff)];
if get(handles.checkbox_defaultview,'value')==1
    view([0 0])
else
    view(-60,0);
end
if ff < 201, sff = 1 : ff;
elseif 201 <= ff && ff < size(Dxyz,3)-199 
    sff = ff-200 : ff+200;
else sff = ff-200 : size(Dxyz,3);
end
plot3(squeeze(Dxyz(xrow,23,sff)),squeeze(Dxyz(yrow,23,sff)),squeeze(Dxyz(zrow,23,sff)),'r:');
plot3(squeeze(Dxyz(xrow,28,sff)),squeeze(Dxyz(yrow,28,sff)),squeeze(Dxyz(zrow,28,sff)),'k:');
plot3(squeeze(Dxyz(xrow,23,:)),squeeze(Dxyz(yrow,23,:)),zeros(zrow,size(Dxyz,3)),'color','k')
axis equal off;
set(gca,'xlim',[rtoe(1)-200 rtoe(1)+200],'ylim',[rtoe(2)-200 rtoe(2)+200],'zlim',[rtoe(3)-20 rtoe(3)+180]);

axes(handles.mapax);
cla; hold on;
for i = 1 : length(body)
    nn = body(i);    
    thisparent = parent(nn);
    if thisparent > 0
        plot3([Dxyz(xrow,thisparent,ff) Dxyz(xrow,nn,ff)],...
            [Dxyz(yrow,thisparent,ff) Dxyz(yrow,nn,ff)],...
            [Dxyz(zrow,thisparent,ff) Dxyz(zrow,nn,ff)],...
            'color',[0 109 219]./256);
    end
end
plot(squeeze(Dxyz(xrow,7,:)),squeeze(Dxyz(yrow,7,:)),'color',[154 154 154]./256);hold on;
class_text('position',[Dxyz(xrow,7,1),Dxyz(yrow,7,1)],'string','START','fontsize',8,'show',1);
view(45,30);
axis equal off;

function liststr = gcinfo2list(matdata,label)
for i = 1 : size(matdata,1)
    strcmd = 'temp = sprintf(''';
    for j = 1 : size(matdata,2)        
        if j == size(matdata,2)
            strcmd = [strcmd '%05d    -    '','];
        else
            strcmd = [strcmd '%05d    '];
        end
    end 
    for j = 1 : size(matdata,2)
        if j == size(matdata,2)
            strcmd = [strcmd 'matdata(i,' num2str(j) '));'];
        else
            strcmd = [strcmd 'matdata(i,' num2str(j) '),'];
        end
    end
    eval(strcmd);
    matlist{i,:} = [sprintf('GC:%02d    -    ',i) temp];
end
liststr = strcat(matlist,label);

function gcinfo = gclist2info(celldata)
gcstr = [];
for i = 1 : length(celldata)
    thisline = celldata{i};
    dashpos = strfind(thisline,'-');
    temp = thisline(dashpos(end)+1:end);
    gclabel{i,:} = temp(~isspace(temp));
    try
        gcstr = [gcstr; thisline(dashpos(1)+1 : dashpos(2)-1)];
    catch        
        fprintf('WARNING: String size is mismatch')
    end
end
gcidx = str2num(gcstr);
gcinfo.label = gclabel;
gcinfo.index = gcidx;

function pushbutton_updir_Callback(hObject,eventdata,handles)
handles=getappdata(handles.figure,'handles');
% dirlist=get(handles.popupmenu_currdir,'string');
% currdir=dirlist{get(handles.popupmenu_currdir,'value')};
currdir=get(handles.combobox_currdir,'selecteditem');
if strfind(currdir,'.\')
    slash=strfind(currdir,'\');
    updir=currdir(1:slash(end));
    if strcmpi(currdir,'.\')
        [updir,~,~]=fileparts(cd);
    end
else
    [updir,~,~]=fileparts(currdir);
end
handles.combobox_currdir.insertItemAt(updir,0);
set(handles.combobox_currdir,'selectedindex',0);
% uijlist_setfiles(handles.jlistbox_filenameinput,updir,'type',{'.all'});
setappdata(handles.figure,'handles',handles);

function combobox_currdir_Callback(hObject,eventdata,handles)
handles=getappdata(handles.figure,'handles');
newdir=get(hObject,'selecteditem');
if strcmpi(newdir,'.\');
    newdir=cd;
end
if ~strcmpi(newdir,hObject.getItemAt(0))
    hObject.insertItemAt(newdir,0);
end
uijlist_setfiles(handles.jlistbox_filenameinput,newdir,'type',{'.all'});
setappdata(handles.figure,'handles',handles);

function timerFcn_Callback(hObject,event,handles)
handles=getappdata(handles.figure,'handles');
ff = str2num(get(handles.edit_frame,'string'));
slider_frame_Callback(handles.slider_frame,[],handles);
updateval = ff+3;
if updateval > get(handles.slider_frame,'max')
    updateval = get(handles.slider_frame,'max'); 
    pushbutton_play_Callback(handles.pushbutton_play,[],handles);
end
set(handles.edit_frame,'string',num2str(updateval));
set(handles.slider_frame,'value',updateval);
% Setappdata
setappdata(handles.figure,'handles',handles);

function timerStopFcn_Callback(hObject,event,handles)
handles=getappdata(handles.figure,'handles');
% Setappdata
setappdata(handles.figure,'handles',handles);

function handles = initialize_gcfile(handles)
handles=getappdata(handles.figure,'handles');
kin = evalin('base','kin');
label = kin.gc.label;
celllist = gcinfo2list(kin.gc.event.index,label);
uisetjlistbox(handles.jlistbox_matdata,celllist);
% Interact with GUI
set(handles.jlistbox_matdata,'SelectedIndex',0);
gcinfo = gclist2info(uigetjlistbox(handles.jlistbox_matdata));
updateuigcevent(gcinfo,handles);
% Setappdata
setappdata(handles.figure,'handles',handles);

function handles=KeyboardThread_Callback(hObject,eventdata,handles)
handles=getappdata(handles.figure,'handles');
% -----------
if isprop(eventdata,'Key')
    key = lower(eventdata.Key); % Matlab component; Ctrl: 'control'
else
    key = lower(char(eventdata.getKeyText(eventdata.getKeyCode)));    % Java component;
end
if any([strcmpi(key,'g'),strcmpi(key,'ctrl'),strcmpi(key,'control'),...
        strcmpi(key,'shift'),strcmpi(key,'alt')])
    handles.keyholder = key;
    setappdata(handles.figure,'handles',handles);
    return;
end
% fprintf('KeyPressed: %s\n',key);
% Go to component;
if strcmpi(handles.keyholder,'g')
    if strcmpi(key,'l') % Set focus on function list
        handles.jlistbox_matdata.requestFocus; 
        fprintf('jlistbox_funclist is selected.\n');
    elseif strcmpi(key,'f') % Set focus on mfile list
        handles.jlistbox_filenameinput.requestFocus;
        fprintf('jlistbox_filenameinput is selected.\n');
    elseif strcmpi(key,'c') % Set focus on popupmenu_currdir
        handles.combobox_currdir.requestFocus;
        fprintf('combobox_currdir is selected.\n');    
    elseif strcmpi(key,'space')
        currval = get(handles.slider_frame,'value');
        newval = currval - 17;
        if newval < 0, newval = newval+17; end;
        set(handles.slider_frame,'value',newval);
        slider_frame_Callback(handles.slider_frame,[],handles);
        handles.keyholder = ''; % reset keyholder;
    end    
elseif strcmpi(handles.keyholder,'shift')
    if strcmpi(key,'return') || strcmpi(key,'enter')
        pushbutton_update_Callback(handles.pushbutton_update,[],handles);            
    end
        
elseif strcmpi(handles.keyholder,'ctrl') || strcmpi(handles.keyholder,'control') && strcmpi(key,'s')
    pushbutton_save_Callback(handles.pushbutton_save,[],handles);
else
    if (strcmpi(key,'return') || strcmpi(key,'enter')) && hObject ~= handles.jlistbox_filenameinput
        pushbutton_insert_Callback(handles.pushbutton_insert,[],handles);        
    elseif (strcmpi(key,'return') || strcmpi(key,'enter')) && hObject == handles.jlistbox_filenameinput
        handles = jlistbox_filenameinput_load(hObject,handles);
    elseif strcmpi(key,'uparrow') || strcmpi(key,'downarrow')
        handles.jlistbox_matdata.requestFocus
    elseif strcmpi(key,'up') || strcmpi(key,'down')
        jlistbox_matdata_Callback(handles.jlistbox_matdata,[],handles);
    elseif strcmpi(key,'left') || strcmpi(key, 'k')
        set(handles.slider_frame,'value',get(handles.slider_frame,'value')-1);
        slider_frame_Callback(handles.slider_frame,[],handles);
    elseif strcmpi(key,'right') || strcmpi(key, 'j')
        set(handles.slider_frame,'value',get(handles.slider_frame,'value')+1);
        slider_frame_Callback(handles.slider_frame,[],handles);
    elseif strcmpi(key,'space')
        currval = get(handles.slider_frame,'value');
        newval = currval + 17;
        if newval > get(handles.slider_frame,'max'), newval = newval-17; end;
        set(handles.slider_frame,'value',newval);
        slider_frame_Callback(handles.slider_frame,[],handles);
    elseif strcmpi(key,'c')                                
        acc_color = [154 154 154]./256;
        for c = 1 : 5
            strcmd = sprintf('editcolor = get(handles.edit_gcevent%d,''backgroundcolor'')',c);    
            eval(strcmd)
            if editcolor ~= acc_color
                strcmd = sprintf('editcolor = set(handles.edit_gcevent%d,''backgroundcolor'',acc_color);',c);    
                eval(strcmd);
                strcmd = sprintf('set(handles.edit_gcevent%d,''string'',get(handles.edit_frame,''string''))',c);   % Add current frame to gait event 1        
                eval(strcmd)
                return
            end
        end                
    elseif strcmpi(key,'backspace')                                
        acc_color = [154 154 154]./256;
        for c = 5 : -1 : 1            
            strcmd = sprintf('editcolor = get(handles.edit_gcevent%d,''backgroundcolor'')',c)  ;          
            eval(strcmd)
            if editcolor == acc_color
                strcmd = sprintf('editcolor = set(handles.edit_gcevent%d,''backgroundcolor'',''w'');',c);    
                eval(strcmd);
                strcmd = sprintf('set(handles.edit_gcevent%d,''string'',''0'')',c);  % Add current frame to gait event 1        
                eval(strcmd)
                return
            end
        end                
    elseif strcmpi(key,'a')                            
        set(handles.edit_gcevent1,'string',get(handles.edit_frame,'string'));   % Add current frame to gait event 1
        set(handles.edit_gcevent1,'backgroundcolor',[154 154 154]./256);
    elseif strcmpi(key,'s') 
        set(handles.edit_gcevent2,'string',get(handles.edit_frame,'string'));   % Add current frame to gait event 2
        set(handles.edit_gcevent2,'backgroundcolor',[154 154 154]./256);
    elseif strcmpi(key,'d') 
        set(handles.edit_gcevent3,'string',get(handles.edit_frame,'string'));   % Add current frame to gait event 3
        set(handles.edit_gcevent3,'backgroundcolor',[154 154 154]./256);
    elseif strcmpi(key,'f') 
        set(handles.edit_gcevent4,'string',get(handles.edit_frame,'string'));   % Add current frame to gait event 4
        set(handles.edit_gcevent4,'backgroundcolor',[154 154 154]./256);
    elseif strcmpi(key,'r') 
        set(handles.edit_gcevent5,'string',get(handles.edit_frame,'string'));   % Add current frame to gait event 5
        set(handles.edit_gcevent5,'backgroundcolor',[154 154 154]./256);
    elseif strcmpi(key,'e') 
        idx = get(handles.combobox_gclabel,'selectedindex');
        if idx == get(handles.combobox_gclabel,'ItemCount')-1, idx = 0;
        else idx = idx + 1; end
        set(handles.combobox_gclabel,'SelectedIndex',idx);
    elseif strcmpi(key,'x') || strcmpi(key,'delete') && hObject == handles.jlistbox_matdata
        pushbutton_del_Callback(handles.pushbutton_del,[],handles);
    elseif strcmpi(key,'f1')
        winopen('.\hotkey.txt');
    elseif strcmpi(key,'f2')        
    elseif strcmpi(key,'numpad-0') || strcmpi(key,'numpad0')
        gclabelIndex = get(handles.combobox_gclabel,'selectedindex');
        itemCounts = handles.combobox_gclabel.getItemCount;
        if gclabelIndex < itemCounts-1
            set(handles.combobox_gclabel,'selectedindex',gclabelIndex+1);
        else
            set(handles.combobox_gclabel,'selectedindex',0);
        end
    elseif strcmpi(key,'numpad-1') || strcmpi(key,'numpad1')
        gclabelIndex = get(handles.combobox_gclabel,'selectedindex');
        itemCounts = handles.combobox_gclabel.getItemCount;
        if gclabelIndex > 0
            set(handles.combobox_gclabel,'selectedindex',gclabelIndex-1);
        else
            set(handles.combobox_gclabel,'selectedindex',itemCounts-1);
        end
    end
end
handles.keyholder = ''; % reset keyholder;
setappdata(handles.figure,'handles',handles);
