part of 'library_crud_mixin.dart';

Future<void> _updateLibraryEntryProgressImpl(
  LibraryCrudMixin self,
  String seriesId, {
  int? progressChapter,
  int? progressVolume,
}) async {
  // Progress is a count; a negative value from a stepper or a typed field
  // would be written locally and sent to the server as-is.
  if (progressChapter != null && progressChapter < 0) progressChapter = 0;
  if (progressVolume != null && progressVolume < 0) progressVolume = 0;

  // Capture state for rollback and auto-completion checks.
  final snapshot = await self.database.libraryEntriesDao.getEntryBySeriesId(
    seriesId,
  );

  String? autoState;
  if (SettingsManager().autoCompleteSeriesStatus ==
          AutoCompleteProgressMode.always &&
      snapshot != null &&
      snapshot.series.status?.toLowerCase() == 'completed' &&
      snapshot.libraryEntry.state != 'completed') {
    final totalChapters = int.tryParse(snapshot.series.totalChapters ?? '');
    final totalVolumes = int.tryParse(snapshot.series.finalVolume ?? '');
    final prevChapter = snapshot.libraryEntry.progressChapter ?? 0;
    final prevVolume = snapshot.libraryEntry.progressVolume ?? 0;
    final reachedChapters =
        progressChapter != null &&
        totalChapters != null &&
        totalChapters > 0 &&
        prevChapter < totalChapters &&
        progressChapter >= totalChapters;
    final reachedVolumes =
        progressVolume != null &&
        totalVolumes != null &&
        totalVolumes > 0 &&
        prevVolume < totalVolumes &&
        progressVolume >= totalVolumes;

    if (reachedChapters || reachedVolumes) {
      autoState = 'completed';
      if (progressVolume == null &&
          totalVolumes != null &&
          totalVolumes > 0 &&
          prevVolume < totalVolumes) {
        progressVolume = totalVolumes;
      }
      if (progressChapter == null &&
          totalChapters != null &&
          totalChapters > 0 &&
          prevChapter < totalChapters) {
        progressChapter = totalChapters;
      }
    }
  }

  self.logger.info(
    'Updating library entry progress for $seriesId — Ch: $progressChapter, Vol: $progressVolume${autoState != null ? ', State: $autoState' : ''} (optimistic)',
  );

  if (autoState != null) {
    await self.database.libraryEntriesDao.updateEntryState(
      seriesId,
      autoState,
      progressChapter: progressChapter,
      progressVolume: progressVolume,
    );
  } else {
    await self.database.libraryEntriesDao.updateEntryProgress(
      seriesId,
      progressChapter: progressChapter,
      progressVolume: progressVolume,
    );
  }

  try {
    final url = Uri.parse('${LibraryConstants.baseUrl}/$seriesId');

    final body = <String, dynamic>{
      if (autoState != null) 'state': autoState,
      if (progressChapter != null) 'progress_chapter': progressChapter,
      if (progressVolume != null) 'progress_volume': progressVolume,
    };

    final response = await self._sendAuthorized(
      'Update progress',
      (headers) => http.put(url, headers: headers, body: jsonEncode(body)),
    );

    if (response.statusCode != 200) {
      self.logger.severe(
        'Failed to update entry progress for $seriesId. Status: ${response.statusCode}',
      );
      // Rolled back once, in the catch below.
      throw ApiException(
        message: 'Failed to update entry progress',
        statusCode: response.statusCode,
        responseBody: response.body,
        code: 'UPDATE_PROGRESS_FAILED',
      );
    }

    self.logger.info('Successfully updated progress for $seriesId on server');
  } catch (e, st) {
    self.logger.severe('Error updating entry progress for $seriesId', e, st);
    try {
      await self._rollbackProgress(
        seriesId,
        snapshot,
        wroteChapter: progressChapter,
        wroteVolume: progressVolume,
        wroteState: autoState,
      );
    } catch (rollbackError, rollbackStack) {
      // Logged, not thrown: the original failure is the one to report.
      self.logger.severe(
        'Progress rollback failed for $seriesId',
        rollbackError,
        rollbackStack,
      );
    }
    self._rethrowAsAppException(e, st, seriesId, 'update entry progress');
  }
}
