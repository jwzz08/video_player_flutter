import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class CustomVideoPlayer extends StatefulWidget {
  final XFile video;
  final VoidCallback onNewVideoPressed;

  const CustomVideoPlayer({
    required this.video,
    required this.onNewVideoPressed,
    Key? key}) : super(key: key);

  @override
  State<CustomVideoPlayer> createState() => _CustomVideoPlayerState();
}

class _CustomVideoPlayerState extends State<CustomVideoPlayer> {
  VideoPlayerController? videoController;

  //현재 포지션을 0부터 시작해서 계속 여기에 저장
  Duration currentPosition = Duration();
  bool showControls = false;

  @override
  void initState() {
    super.initState();

    initializeController();
  }

  //videoController를 initState에서 관리하고 있어서, stateful이 실행중인 상황에서 새로운 동영상을 다시 불러오면
  //화면 업데이트가 되지 않으니 update 위젯을 불러와서 initializeController 함수를 다시 부른다.
  @override
  void didUpdateWidget(covariant CustomVideoPlayer oldWidget){
    super.didUpdateWidget(oldWidget);

    if(oldWidget.video.path != widget.video.path){
      initializeController();
    }
  }

  initializeController() async {
    //매번 초기화 시켜주기
    currentPosition = Duration();

    videoController = VideoPlayerController.file(File(widget.video.path));

    await videoController!.initialize();

    videoController!.addListener(() {
      final currentPosition = videoController!.value.position;

      setState(() {
        this.currentPosition = currentPosition;
      });
    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (videoController == null) {
      return CircularProgressIndicator();
    }

    return AspectRatio(
        //video를 원래 비율대로 설정
        aspectRatio: videoController!.value.aspectRatio,
        child: GestureDetector(
          onTap: (){
            setState(() {
              showControls = !showControls;
            });
          },
          child: Stack(
            children: [
              VideoPlayer(videoController!),
              if(showControls)
                _Controls(
                  onForwardPressed: onForwardPressed,
                  onPlayPressed: onPlayPressed,
                  onReversePressed: onReversePressed,
                  isPlaying: videoController!.value.isPlaying,
                ),
              if(showControls)
                _NewVideo(onPressed: widget.onNewVideoPressed),
              _SliderBottom(
                  currentPosition: currentPosition,
                  maxPosition: videoController!.value.duration,
                  onSliderChanged: onSliderChanged)
            ],
          ),
        ));
  }

  void onSliderChanged(double val) {
    videoController!.seekTo(Duration(seconds: val.toInt()));
  }

  void onForwardPressed() {
    //비디오의 전체 길이를 가져오려면 duration을 사용
    final maxPosition = videoController!.value.duration;
    final currentPosition = videoController!.value.position;

    //position을 전체길이로 초기화(영상의 제일 끝부분)
    Duration position = maxPosition;

    //현재 실행하고 있는 곳이 3초가 지났으면은 (3초 이하일 때 3초 뒤로 가면 마이너스가 되니)
    if ((maxPosition - Duration(seconds: 3)).inSeconds >
        currentPosition.inSeconds) {
      position = currentPosition + Duration(seconds: 3);
    }

    videoController!.seekTo(position);
  }

  void onPlayPressed() {
    //이미 실행중이면 중지
    //실행중이 아니면 실행
    setState(() {
      if (videoController!.value.isPlaying) {
        videoController!.pause();
      } else {
        videoController!.play();
      }
    });
  }

  void onReversePressed() {
    final currentPosition = videoController!.value.position;

    //position을 기본인 0초로 초기화
    Duration position = Duration();

    //현재 실행하고 있는 곳이 3초가 지났으면은 (3초 이하일 때 3초 뒤로 가면 마이너스가 되니)
    if (currentPosition.inSeconds > 3) {
      position = currentPosition - Duration(seconds: 3);
    }

    videoController!.seekTo(position);
  }
}

class _Controls extends StatelessWidget {
  final VoidCallback onPlayPressed;
  final VoidCallback onReversePressed;
  final VoidCallback onForwardPressed;
  final bool isPlaying;

  const _Controls(
      {required this.onPlayPressed,
      required this.onReversePressed,
      required this.onForwardPressed,
      required this.isPlaying,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      //control 버튼이 나타나면 뒷 배경이 어두워지게 설정
      color: Colors.black.withOpacity(0.5),
      height: MediaQuery.of(context).size.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          renderIconButton(
              onPressed: onReversePressed, iconData: Icons.rotate_left),
          renderIconButton(
              onPressed: onPlayPressed,
              iconData: isPlaying ? Icons.pause : Icons.play_arrow),
          renderIconButton(
              onPressed: onForwardPressed, iconData: Icons.rotate_right),
        ],
      ),
    );
  }

  Widget renderIconButton(
      {required VoidCallback onPressed, required IconData iconData}) {
    return IconButton(
      onPressed: onPressed,
      iconSize: 30.0,
      color: Colors.white,
      icon: Icon(iconData),
    );
  }
}

class _NewVideo extends StatelessWidget {
  final VoidCallback onPressed;

  const _NewVideo({required this.onPressed, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 0,
      child: IconButton(
          onPressed: onPressed,
          color: Colors.white,
          iconSize: 30.0,
          icon: Icon(Icons.photo_camera_back)),
    );
  }
}

class _SliderBottom extends StatelessWidget {
  final Duration currentPosition;
  final Duration maxPosition;
  final ValueChanged<double> onSliderChanged;

  const _SliderBottom(
      {required this.currentPosition,
      required this.maxPosition,
      required this.onSliderChanged,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      right: 0,
      left: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            Text(
              '${currentPosition.inMinutes}:${(currentPosition.inSeconds % 60).toString().padLeft(2, '0')}',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            Expanded(
              child: Slider(
                value: currentPosition.inSeconds.toDouble(),
                //onchanged는 내가 직접 슬라이더를 클릭해서 움직일 때 불림
                onChanged: onSliderChanged,
                max: maxPosition.inSeconds.toDouble(),
                min: 0,
              ),
            ),
            Text(
              '${maxPosition.inMinutes}:${(maxPosition.inSeconds % 60).toString().padLeft(2, '0')}',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
