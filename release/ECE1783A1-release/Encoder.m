classdef Encoder
    properties (GetAccess='public', SetAccess='public')
        block_width;
        block_height;
        inputvideo;
        r;
        n;
        QP;
        reconstructedVideo;
        modes;
        MV;
        diff_modes;
        diff_MV;
        I_Period;
        entropyVideo;
        predictionVideo;
    end
    
    methods (Access = 'public')
        function obj = Encoder(inputvideo,block_width, block_height,r ,n, QP, I_Period)
            %UNTITLED2 Construct an instance of this class
            %   Detailed explanation goes here
            obj.inputvideo = inputvideo;
            obj.I_Period = I_Period;
            obj.block_width=block_width;
            obj.block_height=block_height;
            obj.r=r;
            obj.n = n;
            obj.QP = QP;
            obj = obj.encodeVideo();
        end
    
        function [reconstructedFrame, entropyQTC,entropyPredictionInfo] = generateReconstructedFrame(obj,frameIndex, predicted_frame,Diffencoded_frame)
            %calculating residual frame
            residualFrame =  int16(obj.inputvideo.Y(:,:,frameIndex)) -int16(predicted_frame.predictedFrame); 
            %input alculated residual frame to transformation engine
            transformedFrame = dct2(residualFrame);
            %input transformed frame to quantization engine
            quantizedtransformedFrame = QuantizationEngine(transformedFrame,obj.block_width, obj.block_height, obj.QP).quantizationResult;
            
            %call entropy engine to encode the quantized transformed frame
            %and save it.
            entropyFrame = EntropyEngine();
            if (rem(frameIndex - 1,obj.I_Period)) == 0
                %it's I frame
                entropyFrame = entropyFrame.EntropyEngineI(quantizedtransformedFrame,Diffencoded_frame.diff_modes, obj.block_width, obj.block_height,obj.QP);
                entropyQTC = entropyFrame.bitstream;
                entropyPredictionInfo = entropyFrame.predictionInfoBitstream;
            else
                %it's P frame
                entropyFrame = entropyFrame.EntropyEngineP(quantizedtransformedFrame,Diffencoded_frame.diff_motionvector, obj.block_width, obj.block_height,obj.QP);
                entropyQTC = entropyFrame.bitstream;
                entropyPredictionInfo = entropyFrame.predictionInfoBitstream;
            end
            %input quantized transformed frame to rescaling engine    
            rescaledFrame = RescalingEngine(quantizedtransformedFrame,obj.block_width, obj.block_height, obj.QP ).rescalingResult;
            %input rescal transformed frame to inverse transformation engine    
            rescaledFrame = idct2(rescaledFrame);
            %finally, add this frame to predicted frame
            reconstructedFrame = int16(predicted_frame.predictedFrame(:,:,1)) + int16(rescaledFrame(:,:,1));
        end
        
        function type = generateTypeMatrix(obj)
            type = zeros(1, obj.inputvideo.numberOfFrames);
            for i = 1: obj.I_Period:obj.inputvideo.numberOfFrames
                type(i) = 1;
            end
        end
        
        function obj = encodeVideo(obj)
            j = 1;
            k = 1;
            type = obj.generateTypeMatrix();
            %for i = 1: 1:obj.inputvideo.numberOfFrames
            for i = 1: 1:10
                if type(i) == 1
                    %use intra prediction
                    frame = IntraPredictionEngine(obj.inputvideo.Y(:,:,i),obj.block_width,obj.block_height);
                    deframe = DifferentialEncodingEngine();
                    deframe = deframe.differentialEncodingMode(frame.modeFrame);
                    [reconstructedFrame,entropyQTC,entropyPredictionInfo] = obj.generateReconstructedFrame(i,frame,deframe );
                    obj.reconstructedVideo(:,:,i) = uint8(reconstructedFrame);
                    obj.entropyVideo = [obj.entropyVideo entropyQTC];
                    obj.predictionVideo = [obj.predictionVideo entropyPredictionInfo];
                    obj.diff_modes(:,:,j) = deframe.diff_modes;
                    obj.modes(:,:,j)=frame.modeFrame;
                    j = j + 1;
                else
                    frame = MotionEstimationEngine(obj.r,obj.inputvideo.Y(:,:,i), uint8(obj.reconstructedVideo(:,:,i-1)), obj.block_width, obj.block_height,obj.n);
                    deframe = DifferentialEncodingEngine();
                    deframe = deframe.differentialEncodingMotionVector(frame.blocks);
                    [reconstructedFrame,entropyQTC,entropyPredictionInfo] = obj.generateReconstructedFrame(i,frame,deframe );
                    obj.reconstructedVideo(:,:,i) = uint8(reconstructedFrame);
                    obj.entropyVideo = [obj.entropyVideo entropyQTC];
                    obj.predictionVideo = [obj.predictionVideo entropyPredictionInfo];
                    obj.diff_MV(:,:,k) = deframe.diff_motionvector;
                    obj.MV(:,:,k)=frame.blocks;
                    k = k + 1;
                    % realationship between i, j, k
                end
                fprintf("frame number %d is done\n", i);
            end
        end
    end
end