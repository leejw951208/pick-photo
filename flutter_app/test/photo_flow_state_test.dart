import 'package:flutter_test/flutter_test.dart';
import 'package:pick_photo/features/photo_flow/photo_flow_state.dart';

void main() {
  test('initial state waits for upload', () {
    const state = PhotoFlowState.initial();

    expect(state.stage, PhotoFlowStage.waitingForUpload);
    expect(state.faces, isEmpty);
  });

  test('selected face state tracks one face', () {
    const face = DetectedFace(id: 'face-1', faceIndex: 0, confidence: 0.98);
    final state = const PhotoFlowState.initial().copyWith(
      stage: PhotoFlowStage.reviewingFaces,
      faces: [face],
      selectedFaceIds: {'face-1'},
    );

    expect(state.selectedFaceIds, {'face-1'});
  });
}
