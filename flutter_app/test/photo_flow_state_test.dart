import 'package:flutter_test/flutter_test.dart';
import 'package:pick_photo/features/photo_flow/photo_flow_state.dart';

void main() {
  test('initial state waits for upload', () {
    const state = PhotoFlowState.initial();

    expect(state.stage, PhotoFlowStage.waitingForUpload);
    expect(state.faces, isEmpty);
    expect(state.selectedFaceIds, isEmpty);
    expect(state.results, isEmpty);
    expect(state.message, isNull);
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

  test('copyWith can clear a message', () {
    final state = const PhotoFlowState.initial().copyWith(
      message: 'Generation failed',
    );

    final clearedState = state.copyWith(clearMessage: true);

    expect(clearedState.message, isNull);
  });

  test('state collections cannot be mutated from outside', () {
    const face = DetectedFace(id: 'face-1', faceIndex: 0, confidence: 0.98);
    const otherFace =
        DetectedFace(id: 'face-2', faceIndex: 1, confidence: 0.94);
    const result = GeneratedPhoto(
      id: 'result-1',
      faceId: 'face-1',
      url: 'https://example.com/result-1.jpg',
    );
    const otherResult = GeneratedPhoto(
      id: 'result-2',
      faceId: 'face-2',
      url: 'https://example.com/result-2.jpg',
    );
    final faces = <DetectedFace>[face];
    final selectedFaceIds = <String>{'face-1'};
    final results = <GeneratedPhoto>[result];

    final state = PhotoFlowState(
      stage: PhotoFlowStage.completed,
      faces: faces,
      selectedFaceIds: selectedFaceIds,
      results: results,
    );
    final copiedState = const PhotoFlowState.initial().copyWith(
      faces: faces,
      selectedFaceIds: selectedFaceIds,
      results: results,
    );

    faces.add(otherFace);
    selectedFaceIds.add('face-2');
    results.add(otherResult);

    expect(state.faces, [face]);
    expect(state.selectedFaceIds, {'face-1'});
    expect(state.results, [result]);
    expect(copiedState.faces, [face]);
    expect(copiedState.selectedFaceIds, {'face-1'});
    expect(copiedState.results, [result]);
    expect(() => state.faces.add(otherFace), throwsUnsupportedError);
    expect(() => state.selectedFaceIds.add('face-2'), throwsUnsupportedError);
    expect(() => state.results.add(otherResult), throwsUnsupportedError);
  });
}
