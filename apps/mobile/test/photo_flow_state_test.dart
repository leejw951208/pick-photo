import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pick_photo/features/photo_flow/photo_flow_state.dart';

void main() {
  test('initial state waits for upload', () {
    const state = PhotoFlowState.initial();

    expect(state.stage, PhotoFlowStage.waitingForUpload);
    expect(state.faces, isEmpty);
    expect(state.selectedFaceIds, isEmpty);
    expect(state.results, isEmpty);
    expect(state.uploadId, isNull);
    expect(state.message, isNull);
  });

  test('selected face state tracks one face', () {
    const testBox = FaceBox(left: 80, top: 60, width: 240, height: 280);
    const face = DetectedFace(
      id: 'face-1',
      faceIndex: 0,
      box: testBox,
      confidence: 0.98,
    );
    final state = const PhotoFlowState.initial().copyWith(
      stage: PhotoFlowStage.reviewingFaces,
      faces: [face],
      selectedFaceIds: {'face-1'},
    );

    expect(state.selectedFaceIds, {'face-1'});
  });

  test('state can keep source photo bytes for face review', () {
    final sourcePhotoBytes = Uint8List.fromList([1, 2, 3]);
    final state = const PhotoFlowState.initial().copyWith(
      sourcePhotoBytes: sourcePhotoBytes,
    );

    expect(state.sourcePhotoBytes, [1, 2, 3]);

    final clearedState = state.copyWith(clearSourcePhotoBytes: true);

    expect(clearedState.sourcePhotoBytes, isNull);
  });

  test('source photo bytes are snapshotted from inputs', () {
    final constructorBytes = Uint8List.fromList([1, 2, 3]);
    final copyWithBytes = Uint8List.fromList([4, 5, 6]);

    final constructedState = PhotoFlowState(
      stage: PhotoFlowStage.reviewingFaces,
      faces: const [],
      selectedFaceIds: const {},
      results: const [],
      sourcePhotoBytes: constructorBytes,
    );
    final copiedState = const PhotoFlowState.initial().copyWith(
      sourcePhotoBytes: copyWithBytes,
    );

    constructorBytes[0] = 9;
    copyWithBytes[0] = 9;

    expect(constructedState.sourcePhotoBytes, [1, 2, 3]);
    expect(copiedState.sourcePhotoBytes, [4, 5, 6]);
  });

  test('source photo bytes getter returns a defensive copy', () {
    final state = const PhotoFlowState.initial().copyWith(
      sourcePhotoBytes: Uint8List.fromList([1, 2, 3]),
    );

    final returnedBytes = state.sourcePhotoBytes!;
    returnedBytes[0] = 9;

    expect(state.sourcePhotoBytes, [1, 2, 3]);
  });

  test('copyWith can clear a message', () {
    final state = const PhotoFlowState.initial().copyWith(
      message: 'Generation failed',
    );

    final clearedState = state.copyWith(clearMessage: true);

    expect(clearedState.message, isNull);
  });

  test('copyWith can clear an upload id', () {
    final state = const PhotoFlowState.initial().copyWith(
      uploadId: 'upload-1',
    );

    final clearedState = state.copyWith(clearUploadId: true);

    expect(clearedState.uploadId, isNull);
  });

  test('state collections cannot be mutated from outside', () {
    const testBox = FaceBox(left: 80, top: 60, width: 240, height: 280);
    const face = DetectedFace(
      id: 'face-1',
      faceIndex: 0,
      box: testBox,
      confidence: 0.98,
    );
    const otherFace = DetectedFace(
      id: 'face-2',
      faceIndex: 1,
      box: testBox,
      confidence: 0.94,
    );
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
