import cv2
import time
from ultralytics import YOLO
import argparse

def run_yolov8_inference(model_path='yolov8n.pt', camera_index=0):
    # Load the YOLOv8 model
    model = YOLO(model_path)

    # Open the video capture (camera or video file)
    cap = cv2.VideoCapture(camera_index)

    # Set the frame width and height to 640x480
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)

    # Initialize variables for FPS calculation
    prev_time = time.time()
    frame_count = 0
    fps = 0
    # 记录最近 10 帧的处理时间
    frame_times = [0] * 10
    index = 0

    # Loop through the video frames
    while cap.isOpened():
        # Read a frame from the video
        success, frame = cap.read()

        if success:
            # Start timing for FPS calculation
            start_time = time.time()

            # Run YOLOv8 inference on the frame
            results = model(frame)

            # Visualize the results on the frame
            annotated_frame = results[0].plot()

            current_time = time.time()
            # 记录当前帧的处理时间
            frame_times[index] = current_time - prev_time
            index = (index + 1) % 10
            # 计算最近 10 帧的平均处理时间
            avg_time = sum(frame_times) / len(frame_times)
            # 计算平均 FPS
            fps = 1 / avg_time if avg_time > 0 else 0

            prev_time = current_time
            frame_count += 1

            # Display FPS on the frame
            cv2.putText(annotated_frame, f"FPS: {fps:.2f}", (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)

            # Display the annotated frame
            cv2.imshow("YOLOv8 Inference", annotated_frame)

            # Break the loop if 'q' is pressed
            if cv2.waitKey(1) & 0xFF == ord("q"):
                break
        else:
            # Break the loop if the end of the video is reached
            break

    # Release the video capture object and close the display window
    cap.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    # 创建命令行参数解析器
    parser = argparse.ArgumentParser(description='Run YOLOv8 inference on a video stream.')
    # 添加模型路径参数，默认值为 'yolov8n.pt'
    parser.add_argument('--model', type=str, default='yolov8n.pt', help='Path to the YOLOv8 model')
    # 添加摄像头索引或视频文件路径参数，默认值为 0
    parser.add_argument('--camera', type=str, default=0, help='Camera index or video file path')
    # 解析命令行参数
    args = parser.parse_args()

    # 调用函数进行推理
    run_yolov8_inference(model_path=args.model, camera_index=args.camera)
