classdef test_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure        matlab.ui.Figure
        nmLabel         matlab.ui.control.Label
        ButtonGroup     matlab.ui.container.ButtonGroup
        singleButton    matlab.ui.control.RadioButton
        circularButton  matlab.ui.control.RadioButton
        pixel           matlab.ui.control.NumericEditField
        radis           matlab.ui.control.NumericEditField
        startButton     matlab.ui.control.Button
        clearButton     matlab.ui.control.Button
        downloadButton  matlab.ui.control.Button
        mLabel          matlab.ui.control.Label
        mmLabel         matlab.ui.control.Label
        UIAxes          matlab.ui.control.UIAxes
    end

    
    properties (Access = private)
        single_fresnel_flag = false;
        circular_flag = true;
    end
    
    methods (Access = private)
        
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.UIFigure.Name = '夫琅和费衍射仿真';
        end

        % Button pushed function: startButton
        function startButtonPushed(app, event)
            if app.circular_flag == true
                %圆孔衍射
                temp = app.radis.Value; %获取输入的半径
                r = temp * 0.001;       %半径单位转换为m
                lambda=632.8e-9;        %波长
                f=1;                    %焦距
                def=1e-5;               %绘制步长
                xm=20000*lambda*f;       %绘制图像的大小,屏幕上的范围
                [x,y]=meshgrid(-xm:def:xm);%绘制
                s=2*pi*r*sqrt(x.^2+y.^2)./(lambda*f);
                I=4*(besselj(1,s)./(s+eps)).^2;%光强变化

                imshow(I*255,'Parent',app.UIAxes);       %二维图
                
                axis(app.UIAxes,'tight');
                axis(app.UIAxes,'square');
                axis(app.UIAxes,'off');
            
            elseif app.single_fresnel_flag == true
                d = app.radis.Value*0.001;%获取单缝宽度，并转换单位为m
                L=1;                    %屏到缝的距离
                Lambda = 632.8e-9;
                
                Xmax = 5*Lambda*L/d;              %Xmax位置(边界)--单位为：m
                %def = Xmax/(app.pixel.Value*(1e-6));
                %t = int32(def);
                %disp(t);
                x = linspace(-Xmax,Xmax,201);      %坐标取样61份
                light_x = linspace(-d/2,d/2,201);  %单缝宽度上取61份点光源
                y = zeros(1,201);

                for num =1:201
                    r = sqrt((x(num)-light_x).^2 + L^2);   %各波列到点的距离
                    phi = 2*pi.*(r-L)./Lambda;             %相位差
                    sumcos = sum(cos(phi));
                    sumsin = sum(sin(phi));
                    y(num) = (sumsin^ 2 + sumcos^2)./201^2;
                end
                
                I = y * 255;                         %光强归一化 并转为255灰度

                imshow(I,'Parent',app.UIAxes);
                axis(app.UIAxes,'tight');
                axis(app.UIAxes,'square');
                axis(app.UIAxes,'off');
                
            end
        end

        % Button pushed function: downloadButton
        function downloadButtonPushed(app, event)
            lambda = 632.8e-9;
            [FileName,PathName] = uiputfile({'*.jpg','JPEG(*.jpg)';...
                                             '*.bmp','Bitmap(*.bmp)';...
                                             '*.gif','GIF(*.gif)';...
                                             '*.*',  'All Files (*.*)'},...
                                             'Save Picture','Untitled');
            if FileName==0
                disp('保存失败');
                return;
            else
                if(app.circular_flag)
                    pixel_num = lambda * 20000 /(app.pixel.Value*(1e-6));
                elseif(app.single_fresnel_flag)
                    pixel_num = lambda*5/(app.radis.Value*0.001)/(app.pixel.Value*(1e-6));
                end
                
                dpi = pixel_num/(10/2.54);
                temp = int32(dpi);
                
                exportgraphics(app.UIAxes,[PathName,FileName],'Resolution',temp);
            end           
        end

        % Button pushed function: clearButton
        function clearButtonPushed(app, event)
            cla(app.UIAxes,'reset');
        end

        % Selection changed function: ButtonGroup
        function ButtonGroupSelectionChanged(app, event)
            selectedButton = app.ButtonGroup.SelectedObject;
            switch selectedButton.Text
                case '圆孔衍射'
                    app.circular_flag = true;
                    app.single_fresnel_flag = false;
                case '单缝衍射'
                    app.circular_flag = false;
                    app.single_fresnel_flag = true;
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 585 405];
            app.UIFigure.Name = 'MATLAB App';

            % Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            app.UIAxes.Position = [209 98 324 264];

            % Create mmLabel
            app.mmLabel = uilabel(app.UIFigure);
            app.mmLabel.Position = [34 242 132 22];
            app.mmLabel.Text = '圆孔半径/单缝宽度(mm)';

            % Create mLabel
            app.mLabel = uilabel(app.UIFigure);
            app.mLabel.Position = [61 146 77 29];
            app.mLabel.Text = '像素大小(μm)';

            % Create downloadButton
            app.downloadButton = uibutton(app.UIFigure, 'push');
            app.downloadButton.ButtonPushedFcn = createCallbackFcn(app, @downloadButtonPushed, true);
            app.downloadButton.Position = [423 31 110 27];
            app.downloadButton.Text = '下载图片';

            % Create clearButton
            app.clearButton = uibutton(app.UIFigure, 'push');
            app.clearButton.ButtonPushedFcn = createCallbackFcn(app, @clearButtonPushed, true);
            app.clearButton.Position = [246 31 110 27];
            app.clearButton.Text = '清除数据';

            % Create startButton
            app.startButton = uibutton(app.UIFigure, 'push');
            app.startButton.ButtonPushedFcn = createCallbackFcn(app, @startButtonPushed, true);
            app.startButton.Position = [44 31 110 27];
            app.startButton.Text = '生成';

            % Create radis
            app.radis = uieditfield(app.UIFigure, 'numeric');
            app.radis.Position = [41 193 117 37];

            % Create pixel
            app.pixel = uieditfield(app.UIFigure, 'numeric');
            app.pixel.Position = [44 101 117 37];

            % Create ButtonGroup
            app.ButtonGroup = uibuttongroup(app.UIFigure);
            app.ButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @ButtonGroupSelectionChanged, true);
            app.ButtonGroup.Title = '选择';
            app.ButtonGroup.Position = [41 288 117 102];

            % Create circularButton
            app.circularButton = uiradiobutton(app.ButtonGroup);
            app.circularButton.Text = '圆孔衍射';
            app.circularButton.Position = [11 54 70 22];
            app.circularButton.Value = true;

            % Create singleButton
            app.singleButton = uiradiobutton(app.ButtonGroup);
            app.singleButton.Text = '单缝衍射';
            app.singleButton.Position = [11 17 70 22];

            % Create nmLabel
            app.nmLabel = uilabel(app.UIFigure);
            app.nmLabel.Position = [254 361 95 29];
            app.nmLabel.Text = '波长 632.8 nm';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = test_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end