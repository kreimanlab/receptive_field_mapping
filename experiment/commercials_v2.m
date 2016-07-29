function commercials_v2(varargin)

bob = clock;
bob = str2num([num2str(mod(bob(1),100)) num2str(bob(2)) num2str(bob(3)) num2str(bob(4)) num2str(floor(bob(5)/10))]);
rand('twister',bob);

exp_params.subject='m00083';
exp_params.movie = 'Charlie and the Chocolate Factory (PG).m4v';				% Which movie are we showing?
exp_params.send_triggers=1;                  % send triggers to EEG acquisition computer
exp_params.send_image_triggers = 1;				% send triggers at the beginning and end of each commercial image?
exp_params.continue_session=0;					% Are we continuing a previously interrupted session?
exp_params.eyelink=0;                      % set to 1 to use Eyelink
exp_params.monitor_ID = 0;                   %set to 1 to use external monitor, 0 for built-in
exp_params.block_interval=5;						% Seconds between "commercial" blocks
exp_params.n_images_in_block=60;             % number of different images per block
exp_params.image_folder='whole_xor_images_2';            % directory where all images are located
exp_params.fixation_timeout = 10;            % number of seconds to wait at fixation point before asking about recalibration
exp_params.fixation_threshold = 5.0;         % radius in visual angle degrees around fixation point to count as fixation
exp_params.fixation_time = 0.5;              % time in seconds fixation must be maintained before trial starts
exp_params.require_fixation = 1;             % Do we require fixation at the beginning of a block of images before the images start?
exp_params.block_start_n_triggers= 2;
exp_params.block_end_n_triggers= 3;
exp_params.pause_n_triggers= 5;
exp_params.resume_n_triggers= 4;
exp_params.beginning_n_triggers= 6;
exp_params.end_n_triggers= 7;
exp_params.frames_per_trigger = 12;				% number of movie frames (NOT screen refreshes) per one-frame trigger
exp_params.trigger_duration=0.02;
exp_params.trigger_interval=0.1;
exp_params.test_triggers=1;                 % run a trigger test session
exp_params.force_response=0;                 % wait until the subject makes a response
exp_params.background_color=128;
exp_params.pause_after_message=1;
exp_params.pause_before_images=0.3;				% how long to sit with fixation point before showing first image; only when not using Eyelink
exp_params.img_pres_time = 0.175;             % how long each image is presented
exp_params.post_img_time = 0.275;             % how much blank time there is after each image
exp_params.fixation_size=14;
exp_params.fixation_width=2;
exp_params.intro_msg=0;                      % display or not intro message
exp_params.c_key=53;                         % code for the calibration key - `
exp_params.exit_key=41;                      % 'esc' key code for exiting the experiment
exp_params.pause_key=19;							% 'p' key code for pausing the experiment, to resume later - only usable between blocks
exp_params.brief_pause_key = 44;					% space bar to pause in the middle without dropping back to matlab
exp_params.gp_keys={[6 8], [5 7]};				% right shoulders or left shoulders
exp_params.r_keys={[44], [29]};					% space bar or 'z' - use KbName('x') to find codes
exp_params.rewind_after_commercial = 0.9;		% how long to rewind the movie after each commercial



black=0;
mark={'Thank you!','Thank you!!','Thank you!!!','Thank You!!','Thank You!!!'};

% ********** parse arguments **********

for a=1:2:length(varargin)
	argument=lower(cell2mat(varargin(a)));
	value=lower(cell2mat(varargin(a+1)));
	if strcmp(value,'yes') || strcmp(value,'on')
		value=1;
	elseif strcmp(value,'no') || strcmp(value,'off')
		value=0;
	end
	% assign the value to a variable with the same name as the argument
	if isfield(exp_params,argument)
		eval(['exp_params.' argument '=value;'])
	else
		error(['unknown parameter: ' argument]);
	end
end

if length(varargin) > 2 && exp_params.continue_session
	error('You may not specify other parameters if you are continuing a previous session.');
end

if ~exp_params.subject
	error('You must choose a data directory!')
end

% initialize other parameters
c=clock;
if ~exist(fullfile('subjects',exp_params.subject),'dir')
	mkdir(fullfile('subjects',exp_params.subject));
end
session_file=(fullfile('subjects',exp_params.subject,['commercials_' exp_params.subject '-' num2str(c(1)) ...
	'_' num2str(c(2),'%0.2d') '_' num2str(c(3),'%0.2d') '-' ...
	num2str(c(4),'%0.2d') '_' num2str(c(5),'%0.2d') '_' num2str(round(c(6)),'%0.2d') '.mat']));
% ********** start PsychToolbox **********
Screen('Screens');	% make sure all functions (SCREEN.mex) are in memory
HideCursor;	                                % Hides the mouse cursor
FlushEvents('keyDown');

try   % from now on everything is in a try-catch loop so that we can turn off
	% the PsychToolbox screen and go back to Matlab command window in case of an error
	ListenChar(2);
	[window,window_rect]=Screen('OpenWindow',0,exp_params.background_color);
	Priority(MaxPriority(window,'WaitBlanking'));
	Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	background_matrix=exp_params.background_color*ones(window_rect(3),window_rect(4));
	background_screen=Screen('maketexture',window,background_matrix);
	fixation_matrix=exp_params.background_color*ones(exp_params.fixation_size+exp_params.fixation_width);
	fixation_matrix(ceil(exp_params.fixation_size/2-exp_params.fixation_width/2)+1:floor(exp_params.fixation_size/2+exp_params.fixation_width/2+1),:)=black;
	fixation_matrix(:,ceil(exp_params.fixation_size/2-exp_params.fixation_width/2)+1:floor(exp_params.fixation_size/2+exp_params.fixation_width/2+1))=black;
	fixation_screen=Screen('maketexture',window,fixation_matrix);
	fixsize = exp_params.fixation_size;
	Screen(window,'TextFont','Arial');
	Screen(window,'TextSize',30);
	draw_centered_text(window,{'Loading...'},black);
	Screen('flip',window);
	keyboards=GetKeyboardIndices;
	d=PsychHID('Devices');
	igp=find([d.usageValue]==5);
	gpdev=d(igp);
	if ~isempty(gpdev)
		exp_params.device_keys = exp_params.gp_keys;
	else
		exp_params.device_keys = exp_params.r_keys;
	end
	resp_keys=cell2mat(exp_params.device_keys);

	% ********** initialize trigger device **********
	if (exp_params.send_triggers)
		% initialize PMD1208FS
		device=initPMD1208FS;
		if isnumeric(device) && device<0
			error('Trigger device not found');
		else
			device=device.index;
			err=DaqDConfigPort(device,0,0); % port = 0 direction = 0
			FastDaqDout=inline('PsychHID(''SetReport'', device, 2, hex2dec(''04''), uint8([0 port data]))','device', 'port', 'data');
		end
		di = DaqDeviceIndex;
		DaqDConfigPort(di,0,0);
		DaqDOut(di,0,0);
	end
	% ********** run trigger test **********
	if exp_params.test_triggers && exp_params.send_triggers
		draw_centered_text(window,{'Testing triggers'},black);
		Screen('flip',window);
		finished = 0;
		while ~finished
			send_triggers(di,1,exp_params.trigger_duration, 0, 0);
			keycode = WaitForInput(keyboards,[],.5,exp_params.exit_key);
			finished = sum(keycode);
		end
	end

   %set up eyelink
   if exp_params.eyelink
      c=clock;
      eyelink_file = [exp_params.subject(end-2:end) num2str(mod(c(3),10),'%0.1d') num2str(c(4),'%0.2d') num2str(c(5),'%0.2d') '.edf'];
      eyelink_setup_and_calibrate(window, window_rect, eyelink_file)
   end
   
	% read lists of image file names
	image_list=dir(fullfile(exp_params.image_folder,'*.png'));
	n_images=length(image_list);
	image_list={image_list.name};
	% find categories
	exp_params.categories={};
	for img_index=1:n_images
		img_name=image_list{img_index};
		curr_category=img_name(1:findstr(img_name,'_')-1);

		if ~any(strcmp(exp_params.categories,curr_category))
			exp_params.categories=[exp_params.categories,curr_category];
		end
	end
	n_categories=length(exp_params.categories);
% 	if mod(n_images,n_categories)~=0
% 		error('Possibly an unequal number of objects per category');
% 	end

	% read images
	img_mat=cell(1,n_images);
	img_size = [0 0];
	for img_index=1:n_images
		img_name=image_list{img_index};
		img_category=img_name(1:findstr(img_name,'_')-1);
		exp_params.image_categories(img_index)=find(strcmp(exp_params.categories,img_category));
		[img_mat{img_index}(:,:,1:3), junk, alpha_mat]=imread(fullfile(exp_params.image_folder,img_name));
		img_mat{img_index} = cat(3, img_mat{img_index}(:,:,1), alpha_mat);
      

		tmp_img_size = [size(img_mat{img_index}, 1) size(img_mat{img_index}, 2)];
		if img_size == [0 0]
			img_size = tmp_img_size;
		end
		if (diff(tmp_img_size) || sum(mod(tmp_img_size, 2)) || sum(img_size ~= tmp_img_size))
			error(['Images must be square, of the same size, and with even dimensions. ' img_name ' fails these criteria.']);
		end
		
		img_textures(img_index) = Screen(window,'MakeTexture',img_mat{img_index});
	end
	img_size = img_size(1);

	
	
	
	[mov_ptr, exp_params.mov_duration, exp_params.fps, mov_w, mov_h] = Screen('OpenMovie', window, exp_params.movie);
   
   
   
   
	window_aspect = window_rect(3) / window_rect(4);
	mov_aspect = mov_w / mov_h;
	if mov_aspect > window_aspect
		mov_rect = [0 floor((window_rect(4)-window_rect(3)/mov_aspect)/2) window_rect(3) floor((window_rect(4)+window_rect(3)/mov_aspect)/2)];
	else
		mov_rect = [floor((window_rect(3)-window_rect(4)*mov_aspect)/2) 0 floor((window_rect(3)+window_rect(4)*mov_aspect)/2) window_rect(4)];
	end
	exp_params.n_blocks = ceil(exp_params.mov_duration/(exp_params.block_interval - exp_params.rewind_after_commercial));
	image_indices = repmat((1:n_images)', [ceil(exp_params.n_blocks * exp_params.n_images_in_block / n_images), 1]);
	n_indices = length(image_indices);
	rand_index = randperm(n_indices)';
	blocksize = exp_params.n_images_in_block;
	for block_index=1:exp_params.n_blocks
		trials_in_block = rand_index((1+(block_index-1)*blocksize):block_index*blocksize);
		block_struct(block_index).presentations = image_indices(trials_in_block);
		block_struct(block_index).pause_start_times = [];
		block_struct(block_index).pause_stop_times = [];
		block_struct(block_index).trigger_movie_times = [];
		block_struct(block_index).trigger_movie_getsecs = [];
		block_struct(block_index).pause_start_triggers = [];
		block_struct(block_index).pause_stop_triggers = [];
	end

	if exp_params.continue_session
		try
			load('commercials_paused_session.mat');
		catch
			error('Unable to load commercials_paused_session.mat');
		end
		starting_block = block_index;
		clip_start_time = block_struct(block_index).clip_start_time;
		if exp_params.send_triggers
			send_triggers(di,exp_params.resume_n_triggers,exp_params.trigger_duration,exp_params.trigger_interval, exp_params.eyelink);
		end
	else
		starting_block = 1;
		clip_start_time = 0;
		if exp_params.send_triggers
			send_triggers(di,exp_params.beginning_n_triggers,exp_params.trigger_duration,exp_params.trigger_interval, exp_params.eyelink);
		end
   end

   % save presentation order to session file
	save(session_file,'image_list','block_struct','exp_params');
	
	for block_index = starting_block:exp_params.n_blocks
		block_struct(block_index).clip_start_time = clip_start_time;
		Screen('PlayMovie', mov_ptr, 1);
		if block_index == starting_block
			Screen('SetMovieTimeIndex', mov_ptr, clip_start_time);
		end
		frame_cycle_counter = 0;
		clip_start = GetSecs;
		clip_started = 0;
		while GetSecs - clip_start < exp_params.block_interval
			texture_ptr = Screen('GetMovieImage', window, mov_ptr, 0);
			if texture_ptr < 0
				save(session_file,'block_struct','-append');
				end_the_movie(mov_ptr, window, exp_params, di);
			end
			if texture_ptr > 0
				frame_cycle_counter = mod(frame_cycle_counter + 1, exp_params.frames_per_trigger);
				if exp_params.send_triggers && frame_cycle_counter == 1
					turn_off_trigger(di);
				end
				Screen('DrawTexture', window, texture_ptr, [], mov_rect);
				Screen('Flip', window);
				block_struct(block_index).last_frame_getsecs = GetSecs;
				if ~clip_started
					clip_started = block_struct(block_index).last_frame_getsecs;
					block_struct(block_index).clip_start_getsecs = clip_started;
				end
				%We don't want to send a frame trigger too close to the beginning of a block - it could be left on, if it's the frame
				%immediately before a block, or it could confuse the finding of the block-start triggers if it's close.
				if ~frame_cycle_counter && exp_params.send_triggers && GetSecs - clip_start + exp_params.trigger_interval*2 < exp_params.block_interval
					turn_on_trigger(di,exp_params.eyelink);
					block_struct(block_index).trigger_movie_times(end + 1) = Screen('GetMovieTimeIndex', mov_ptr);
					block_struct(block_index).trigger_movie_getsecs(end + 1) = GetSecs;
				end
				Screen('Close', texture_ptr);
			end
			[keyIsDown,secs,keyCode]=KbCheck;
			if keyIsDown==1
				if keyCode(exp_params.exit_key)
					if exp_params.send_triggers
						turn_off_trigger(di);
						WaitSecs(.2)
						send_triggers(di,exp_params.end_n_triggers,exp_params.trigger_duration,exp_params.trigger_interval, exp_params.eyelink);
					end
					Screen('CloseMovie', mov_ptr);
					error('Movie aborted by user.');
				end
				if keyCode(exp_params.pause_key)
					if exp_params.send_triggers
						turn_off_trigger(di);
						WaitSecs(.2)
						send_triggers(di,exp_params.pause_n_triggers,exp_params.trigger_duration,exp_params.trigger_interval, exp_params.eyelink);
					end
					Screen('CloseMovie', mov_ptr);
					save('commercials_paused_session.mat', 'exp_params', 'block_struct', 'block_index');
               if exp_params.eyelink
                  close_eyelink_file(exp_params, eyelink_file)
               end
					error('Pause key pressed. You can resume this session later.');
				end
				if keyCode(exp_params.brief_pause_key)
					block_struct(block_index).pause_start_times = [block_struct(block_index).pause_start_times; GetSecs];
					Screen('PlayMovie', mov_ptr, 0);
					if exp_params.send_triggers
						turn_off_trigger(di);
						WaitSecs(.2)
						block_struct(block_index).pause_start_triggers(end + 1) = GetSecs;
						send_triggers(di,exp_params.pause_n_triggers,exp_params.trigger_duration,exp_params.trigger_interval, exp_params.eyelink);
					else
						WaitSecs(.2)
					end
					
					keycode = WaitForInput(keyboards,[],0,exp_params.exit_key);
					while find(keycode) == exp_params.c_key
						Calibrate(window,ct2,keyboards,gpdev,exp_params.exit_key);
						keycode = WaitForInput(keyboards,[],0,exp_params.exit_key);
					end

					if exp_params.send_triggers
						block_struct(block_index).pause_stop_triggers(end + 1) = GetSecs;
						send_triggers(di,exp_params.resume_n_triggers,exp_params.trigger_duration,exp_params.trigger_interval, exp_params.eyelink);
					end
					Screen('PlayMovie', mov_ptr, 1);
					block_struct(block_index).pause_stop_times = [block_struct(block_index).pause_stop_times; GetSecs];
					clip_start = clip_start + block_struct(block_index).pause_stop_times(end) - block_struct(block_index).pause_start_times(end);
				end
			end
		end
		Screen('PlayMovie', mov_ptr, 0);
		clip_end_time = Screen('GetMovieTimeIndex', mov_ptr);
		block_struct(block_index).clip_end_time = clip_end_time;
		clip_start_time = clip_end_time - exp_params.rewind_after_commercial;
		Screen('SetMovieTimeIndex', mov_ptr, clip_start_time);
		
		%Do the commercial here
		c=clock;
		block_struct(block_index).start_time=[num2str(c(4),'%0.2d') ':' num2str(c(5),'%0.2d') ':' num2str(round(c(6)),'%0.2d')];
		Screen('drawtexture',window,fixation_screen);
		Screen('flip',window);
		pt_time = GetSecs;
      if exp_params.send_triggers
         send_triggers(di,exp_params.block_start_n_triggers,exp_params.trigger_duration,exp_params.trigger_interval, exp_params.eyelink);   % block start triggers
      end
      block_struct(block_index).start_getsecs = pt_time;

      if exp_params.eyelink && exp_params.require_fixation
         good_fixation = 0;
         while ~good_fixation
            good_fixation = fixation_point(window, fixation_screen, window_rect(3)/2, window_rect(4)/2, exp_params.fixation_threshold, exp_params.fixation_time, exp_params.fixation_timeout);
            if ~good_fixation
               draw_centered_text(window,{'Unable to detect fixation. Recalibrate (y/n)?'},black);
               Screen('flip',window);
               key_code = WaitForInput(keyboards,gpdev,0,exp_params.exit_key);
               if find(key_code, 1) == 28
                  close_eyelink_file(exp_params, eyelink_file)
                  eyelink_file = [exp_params.subject(end-2:end) num2str(mod(c(3),10),'%0.1d') num2str(c(4),'%0.2d') num2str(c(5),'%0.2d') '.edf'];
                  eyelink_setup_and_calibrate(window, window_rect, eyelink_file)
               end
            end
         end
      else
         WaitSecs(exp_params.pause_before_images + pt_time - GetSecs);
      end

		presentations=block_struct(block_index).presentations;
		for pres_index=1:exp_params.n_images_in_block
			img_index = presentations(pres_index);
			Screen('drawtexture', window, img_textures(img_index));
			Screen('flip',window);
			pretriggertime = GetSecs;
			if exp_params.send_triggers && exp_params.send_image_triggers
				send_triggers(di,1,exp_params.trigger_duration,exp_params.trigger_interval, exp_params.eyelink);   % target trigger
			end
			WaitSecs(exp_params.img_pres_time-GetSecs+pretriggertime);
			Screen('drawtexture',window,fixation_screen);
			Screen('flip',window);
			post_stim_time = GetSecs;
			if exp_params.send_triggers && exp_params.send_image_triggers
				send_triggers(di,1,exp_params.trigger_duration, 0, exp_params.eyelink); % "off" trigger
			end
			WaitSecs(exp_params.post_img_time);
			block_struct(block_index).pres_time(pres_index) = pretriggertime;
			block_struct(block_index).pres_stop_time(pres_index) = post_stim_time;
		end   % for pres_index=...
		c=clock;
		block_struct(block_index).end_time=[num2str(c(4),'%0.2d') ':' num2str(c(5),'%0.2d') ':' num2str(round(c(6)),'%0.2d')];

		save(session_file,'block_struct','-append');
		stop_getsecs = GetSecs;
		if exp_params.send_triggers
			send_triggers(di,exp_params.block_end_n_triggers,exp_params.trigger_duration,exp_params.trigger_interval, exp_params.eyelink);  % block end triggers
		end
		block_struct(block_index).stop_getsecs = stop_getsecs;
	end

   if exp_params.eyelink
      close_eyelink_file(exp_params, eyelink_file)
   end


	% ********** show goodbye screen **********
	if exp_params.intro_msg
		draw_centered_text(window,{'Thank you!'},black);
		Screen('flip',window);
		WaitSecs(1);
		WaitForInput(keyboards,gpdev,0,exp_params.exit_key);
	end
catch
   if exp_params.eyelink
      close_eyelink_file(exp_params, eyelink_file)
   end
	ListenChar(0);
	err = lasterror;
	disp(err.message);
	for stack_ind = 1:length(err.stack)
		disp(err.stack(stack_ind));
	end
	%disp(lasterr);
end

ListenChar(0);
ShowCursor;
clear Screen;

end
% -- end of main function --

% -------- function definitions -----------------

function end_the_movie(mov_ptr, window, exp_params, di)
Screen('CloseMovie', mov_ptr);
draw_centered_text(window,{'Thank you!'},0);
Screen('flip',window);
WaitSecs(.2)
if exp_params.send_triggers
	send_triggers(di,exp_params.end_n_triggers,exp_params.trigger_duration,exp_params.trigger_interval, exp_params.eyelink);
end
WaitSecs(1)
error('The movie is over!')
end
% -- end of function --


function close_eyelink_file(exp_params, eyelink_file)
c=clock;
local_eyelink_file = fullfile('subjects', exp_params.subject,['eyemovements_commercials_' exp_params.subject '-' num2str(c(1)) ...
   '_' num2str(c(2),'%0.2d') '_' num2str(c(3),'%0.2d') '-' num2str(c(4),'%0.2d') '_' num2str(c(5),'%0.2d') '_' num2str(round(c(6)),'%0.2d') '.edf']);
status = Eyelink('closefile');
if status ~= 0
   disp(sprintf('closefile error, status: %d', status))
end
status = Eyelink('ReceiveFile', eyelink_file, local_eyelink_file);
if status ~= 0
   disp(sprintf('receivefile error, status: %d', status))
end
end
% -- end of function --


function w=TestCalTexture(exp_params,window)

dy=400;
dx=400;
zz=cell(1,5);
for i=1:5
	zz{i}=imread(['calimg/' int2str(i) '.tif']);
end
[ypix,xpix]=size(zz{1});
pos=[round((dy+ypix)/2) round((dx+xpix)/2);0,0;0 dx+xpix;ypix+dy 0;ypix+dy dx+xpix];
zz2=exp_params.background_color*ones(dy+2*ypix,dx+2*xpix);
for i=1:5
	zz2(pos(i,1)+1:pos(i,1)+ypix,pos(i,2)+1:pos(i,2)+xpix)=zz{i};
end

w=Screen(window,'MakeTexture',zz2);

end
% -- end of function --

function w=CalTexture(exp_params,window)

dy=400;
dx=400;
zz=imread('calimg/dog.tif');
[ypix,xpix]=size(zz);
pos=[round((dy+ypix)/2) round((dx+xpix)/2);0,0;0 dx+xpix;ypix+dy 0;ypix+dy dx+xpix];
w=cell(1,6);
for i=1:5
	zz2=exp_params.background_color*ones(dy+2*ypix,dx+2*xpix);
	zz2(pos(i,1)+1:pos(i,1)+ypix,pos(i,2)+1:pos(i,2)+xpix)=zz;
	w{i}=Screen(window,'MakeTexture',zz2);
end
w{6}=w{1};

end
% -- end of function --

function Calibrate(window,ct2,keyboards,gpdev,exit_key)

WaitSecs(0.2);
for i=1:6
	Screen('DrawTexture',window,ct2{i});
	Screen('flip',window);
	WaitForInput(keyboards,gpdev,0,exit_key);
	WaitSecs(0.2);
end

end
% -- end of function --

function [w,pos]=IntroScreen(exp_params,keyboards,gpdev,window)

dy=30;
ddx=50;
dx=400;
wt={'Welcome!',' ','This experiment investigates the mechanism of the image recognition.',' ',...
	'You will be shown a sequence of images.',' ','Look at the images',' ','and press the corresponding key as indicated in the following instructions.'};
draw_centered_text(window,wt,0)
Screen('flip',window);
WaitForInput(keyboards,gpdev,0,exp_params.exit_key);

zz=cell(1,length(exp_params.categories));
z2=cell(1,length(exp_params.categories)+1);
for i=1:length(exp_params.categories)
	zz{i}=imread(['auximg/t' exp_params.categories{i} '.tif']);
	z2{i}=imread(['auximg/gpad' int2str(i) '.tif']);
end
z2{i+1}=imread('auximg/gpad0.tif');

nn=ceil(length(exp_params.categories)/2);
[ypix,xpix]=size(zz{1});
[ypix2,xpix2]=size(z2{1});

zz2=exp_params.background_color*ones((nn-1)*dy+nn*ypix,dx+2*xpix);
[nr nc]=size(zz2);
%pos=repmat([2*ypix,0],length(zz),1);
pos=repmat([ypix,0],length(zz),1);
pos(1:2,2)=ddx;
pos(3:4,2)=nc-ddx-xpix;
pos(5,:)=[nr-ypix,round(nc/2)];
w=zeros(5,2);

for i=1:length(exp_params.categories)
	zz3=zz2;
	zz4=zz2;
	zz3(round((nr-ypix2)/2)+1:round((nr-ypix2)/2)+ypix2,round((nc-xpix2)/2)+1:round((nc-xpix2)/2)+xpix2)=z2{i};
	zz3(pos(i,1)+(1:ypix),pos(i,2)+(1:xpix))=zz{i};
	zz4(round((nr-ypix2)/2)+1:round((nr-ypix2)/2)+ypix2,round((nc-xpix2)/2)+1:round((nc-xpix2)/2)+xpix2)=z2{6};
	zz4(pos(i,1)+(1:ypix),pos(i,2)+(1:xpix))=zz{i};
	w(i,1)=Screen(window,'MakeTexture',zz3);
	w(i,2)=Screen(window,'MakeTexture',zz4);
end

for i=1:5
	b=1;
	while b
		Screen('DrawTexture',window,w(i,1));
		Screen('flip',window);
		WaitSecs(0.2);
		Screen('DrawTexture',window,w(i,2));
		Screen('flip',window);
		[key_code,key_time]=WaitForGp(keyboards,gpdev,0.2,exp_params.exit_key);
		kl=find(key_code);
		if kl
			if any(exp_params.device_keys{i}==kl)
				b=0;
			end
		end
	end
end

WaitSecs(0.5);
wt={'You are ready!',' ','Press any key to start.'};
draw_centered_text(window,wt,0)
Screen('flip',window);
WaitForInput(keyboards,gpdev,0,exp_params.exit_key);

end
% -- end of function --

function [w,pos]=ITtextureGP(exp_params,window,win_size)

dy=30;
ddx=50;
dx=400;
zz=cell(1,length(exp_params.categories));
z2=cell(1,length(exp_params.categories));
for i=1:length(exp_params.categories)
	zz{i}=imread(['auximg/t' exp_params.categories{i} '.tif']);
	z2{i}=imread(['auximg/tgpad' int2str(i) '.tif']);
end
nn=ceil(length(exp_params.categories)/2);
[ypix,xpix]=size(zz{1});
pos=repmat([round(ypix/2),0],length(zz),1);
zz2=exp_params.background_color*ones((nn-1)*dy+nn*ypix,dx+2*xpix);
zz2(1:ypix,1:xpix)=z2{1};
zz2(1:ypix,xpix+(1:xpix))=zz{1};
zz2(dy+(ypix+1:2*ypix),1:xpix)=z2{2};
zz2(dy+(ypix+1:2*ypix),xpix+(1:xpix))=zz{2};
zz2(1:ypix,dx+2*ddx+(1:xpix))=z2{3};
zz2(1:ypix,dx+2*ddx+(1:xpix)-xpix)=zz{3};
zz2(dy+(ypix+1:2*ypix),dx+xpix+(1:xpix))=z2{4};
zz2(dy+(ypix+1:2*ypix),dx+(1:xpix))=zz{4};
zz2(2*dy+(2*ypix+1:3*ypix),round(dx/2)+ddx+(1:xpix))=z2{5};
zz2(2*dy+(ypix+1:2*ypix),round(dx/2)+ddx+(1:xpix))=zz{5};
pos=pos+[0 0;ypix+dy ddx;0 dx+2*ddx  ;ypix+dy dx+ddx;2*ypix+2*dy round(dx/2)+ddx];
pos(:,1)=pos(:,1)+round((win_size(4)-size(zz2,1))/2);
pos(:,2)=pos(:,2)+round((win_size(3)-size(zz2,2))/2)+xpix+20;
w=Screen(window,'MakeTexture',zz2);

end
% -- end of function --

function [w,pos]=ITtexture(exp_params,window,win_size)

dy=30;
ddx=50;
dx=400;
zz=cell(1,length(exp_params.categories));
z2=cell(1,length(exp_params.categories));
for i=1:length(exp_params.categories)
	zz{i}=imread(['auximg/t' exp_params.categories{i} '.tif']);
end
nn=ceil(length(exp_params.categories)/2);
[ypix,xpix]=size(zz{1});
pos=repmat([round(ypix/2),0],length(zz),1);
zz2=exp_params.background_color*ones((nn-1)*dy+nn*ypix,dx+2*xpix);
zz2(1:ypix,1:xpix)=zz{1};
zz2(dy+(ypix+1:2*ypix),1:xpix)=zz{2};
zz2(1:ypix,dx+2*ddx+(1:xpix))=zz{3};
zz2(dy+(ypix+1:2*ypix),dx+2*ddx+(1:xpix))=zz{4};
zz2(2*dy+2*ypix+(1:ypix),round(dx/2)+2*ddx+(1:xpix))=zz{5};
pos=pos+[0 0;ypix+dy ddx;0 dx+2*ddx  ;ypix+dy dx+ddx;2*ypix+2*dy round(dx/2)+ddx];
pos(:,1)=pos(:,1)+round((win_size(4)-size(zz2,1))/2);
pos(:,2)=pos(:,2)+round((win_size(3)-size(zz2,2))/2)+xpix+20;
w=Screen(window,'MakeTexture',zz2);

end
% -- end of function --

function drawITscreen(window,w)

Screen('DrawTexture',window,w);

end
% -- end of function --


function [key_code, t]=WaitForInput(keyboards,gpdev,duration,exit_key)

start_time=GetSecs();
t = start_time;

if ~isempty(gpdev)
	elements=PsychHID('Elements',gpdev.index);
	idx=find([elements.usagePageValue]==9);
	n=length(idx);
end

b=0;

while ~b && (GetSecs()-start_time<duration || duration==0)
	[key_down,secs,key_code]=KbCheck(keyboards(1));
	[x,y,button]=GetMouse;
	if any([button key_down])
		b=1;
	end
	gpbutton=0;
	if ~isempty(gpdev)
		while (~b && gpbutton<n)
			gpbutton=gpbutton+1;
			b=PsychHID('RawState',gpdev.index,idx(gpbutton));
		end
	end
	t = GetSecs;
	if key_code(exit_key)==1
		error('Exit key pressed!');
	end
end

if gpbutton
	key_code = zeros(1,n);
	key_code(gpbutton) = 1;
end

if GetSecs()-start_time<duration
	WaitSecs(start_time+duration-GetSecs());
end

end
% -- end of function --

function send_triggers(device,n_triggers,trigger_duration,trigger_interval, use_eyelink)

for i=1:n_triggers
   on_time = GetSecs;
	DaqDOut(device,0,1);
   if use_eyelink
      Eyelink('Message', 'TRIGGER');
   end
	WaitSecs(trigger_duration - GetSecs + on_time);
	DaqDOut(device,0,0);
	if i<n_triggers
		WaitSecs(trigger_interval - GetSecs + on_time);
	end
end

end
% -- end of function --

function turn_on_trigger(device, use_eyelink)
DaqDOut(device,0,1);
if use_eyelink
   Eyelink('Message', 'TRIGGER');
end
end
% -- end of function --

function turn_off_trigger(device)
DaqDOut(device,0,0);
end
% -- end of function --
