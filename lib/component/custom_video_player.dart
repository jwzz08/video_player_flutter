import 'dart:ffi';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class CustomVideoPlayer extends StatefulWidget {
  final XFile video;

  const CustomVideoPlayer({required this.video, Key? key}) : super(key: key);

  @override
  State<CustomVideoPlayer> createState() => _CustomVideoPlayerState();
}

class _CustomVideoPlayerState extends State<CustomVideoPlayer> {
  VideoPlayerController? videoController;

  @override
  void initState() {
    super.initState();

    initializeController();
  }

  initializeController() async {
    videoController = VideoPlayerController.file(File(widget.video.path));

    await videoController!.initialize();

    setState(() {

    });
  }

  @override
  Widget build(BuildContext context) {
    if (videoController == null) {
      return CircularProgressIndicator();
    }

    return AspectRatio(
        //video를 원래 비율대로 설정
        aspectRatio: videoController!.value.aspectRatio,
        child: Stack(
          children: [
            VideoPlayer(videoController!),
            _Controls(
              onForwardPressed: onForwardPressed,
              onPlayPressed: onPlayPressed,
              onReversePressed: onReversePressed,
              isPlaying: videoController!.value.isPlaying,
            ),
            Positioned(
              right: 0,
              child: IconButton(
                  onPressed: () {},
                  color: Colors.white,
                  iconSize: 30.0,
                  icon: Icon(Icons.photo_camera_back)),
            )
          ],
        ));
  }

  void onForwardPressed(){
    //비디오의 전체 길이를 가져오려면 duration을 사용
    final maxPosition = videoController!.value.duration;
    final currentPosition = videoController!.value.position;

    //position을 전체길이로 초기화(영상의 제일 끝부분)
    Duration position = maxPosition;

    //현재 실행하고 있는 곳이 3초가 지났으면은 (3초 이하일 때 3초 뒤로 가면 마이너스가 되니)
    if((maxPosition - Duration(seconds: 3)).inSeconds > currentPosition.inSeconds ) {
      position = currentPosition + Duration(seconds: 3);
    }

    videoController!.seekTo(position);
  }

  void onPlayPressed(){
    //이미 실행중이면 중지
    //실행중이 아니면 실행
    setState(() {
      if(videoController!.value.isPlaying){
        videoController!.pause();
      }
      else {
        videoController!.play();
      }
    });
  }

  void onReversePressed(){
    final currentPosition = videoController!.value.position;

    //position을 기본인 0초로 초기화
    Duration position = Duration();

    //현재 실행하고 있는 곳이 3초가 지났으면은 (3초 이하일 때 3초 뒤로 가면 마이너스가 되니)
    if(currentPosition.inSeconds > 3) {
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

  const _Controls({
  required this.onPlayPressed,
  required this.onReversePressed,
  required this.onForwardPressed,
  required this.isPlaying,
  Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      //control 버튼이 나타나면 뒷 배경이 어두워지게 설정
      color: Colors.black.withOpacity(0.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          renderIconButton(onPressed: onReversePressed, iconData: Icons.rotate_left),
          renderIconButton(onPressed: onPlayPressed, iconData: isPlaying? Icons.pause : Icons.play_arrow),
          renderIconButton(onPressed: onForwardPressed, iconData: Icons.rotate_right),
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
