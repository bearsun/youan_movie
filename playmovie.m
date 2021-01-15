function playmovie(debug)
% PLAYMOVIE play movie for subjects at Youan
% Movie: Almost a Comedy (2019) 1:06 - 21:06
% Adapted from SimpleMovieDemo
% Liwei Sun, 1/14/21

run = input('run?', 's');
if debug
    ntriggers = 1;
else
    ntriggers = 37;
end
AssertOpenGL;
sid = 0;
moviename = [pwd, '/mclip_3-', run, '.mp4'];
kesc = KbName('Escape');

% MR parameters
tr = 0;
pretr = 5 * ntriggers; % wait 5 TRs for BOLD to be stable
postwait = 20;
if debug
    BUFFER = [];
    fRead = @() ReadFakeTrigger;
    tr_tmr = timer('TimerFcn', @SetTrigger, 'Period', 2, ...
        'ExecutionMode', 'fixedDelay', 'Name', 'tr_timer');
else
    tbeginning = NaN;
    trigger = 57; %GE scanner with MR Technology Inc. trigger box
    IOPort('Closeall');
    P4 = getport;
    fRead = @() ReadScanner;
end

win = Screen('OpenWindow', sid, 0);

% Open movie file:
movie = Screen('OpenMovie', win, moviename);

% Start playback engine:
Screen('PlayMovie', movie, 1);

if debug
    start(tr_tmr);
end

TRWait(pretr);
disp('start');
% Playback loop: Runs until end of movie or keypress:
while ~checkkey(kesc)
    % Wait for next movie frame, retrieve texture handle to it
    tex = Screen('GetMovieImage', win, movie);
    
    % Valid texture returned? A negative value means end of movie reached:
    if tex<=0
        % We're done, break out of loop:
        break;
    end
    
    % Draw the new texture immediately to screen:
    Screen('DrawTexture', win, tex);
    
    % Update display:
    Screen('Flip', win);
    
    % Release texture:
    Screen('Close', tex);
end

% Stop playback:
Screen('PlayMovie', movie, 0);

% Close movie:
Screen('CloseMovie', movie);
Screen('Flip', win);
WaitSecs(postwait);
% Close Screen, we're done:
sca;

if debug
    StopTimer;
else
    IOPort('Closeall');
end

    function [data, when] = ReadScanner
        [data, when] = IOPort('Read', P4);
        
        if ~isempty(data)
            fprintf('data: %d\n', data);
            tr = tr + sum(data == trigger);
            if tr == 1
                tbeginning = when;
            end
            fprintf('%d\t %d\n', when-tbeginning, tr);
        end
    end

    function TRWait(t)
        while t > tr
            fRead();
            WaitSecs(.01);
        end
    end

    function [data, when] = ReadFakeTrigger
        data = BUFFER;
        BUFFER = [];
        %         [~, ~, kDown] = KbCheck;
        %         b = logical(kDown(BUTTONS));
        %         BUFFER = [BUFFER CODES(b)];
        when = GetSecs;
    end

    function SetTrigger(varargin)
        tr = tr + 1;
        fprintf('TR TRIGGER %d\n', tr);
        BUFFER = [BUFFER 53];
    end

    function StopTimer
        if isobject(tr_tmr) && isvalid(tr_tmr)
            if strcmpi(tr_tmr.Running, 'on')
                stop(tr_tmr);
            end
            delete(tr_tmr);
        end
    end

    function b = checkkey(kesc)
        [keyIsDown, ~, keyCode] = KbCheck();
        b = 0;
        if keyIsDown && find(keyCode) == kesc
            b = 1;
        end
    end
end
