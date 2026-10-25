/// One page of a paginated list, with whether another follows.
///
/// These endpoints report `pagination.next` rather than a total, so "is there
/// more" is the only thing a caller can always know. [total] is filled when
/// the response carries `pagination.count`.
class PagedList<T> {
  final List<T> items;
  final bool hasNext;
  final int? total;

  const PagedList(this.items, {required this.hasNext, this.total});
}

/// Whether a paginated response says another page follows.
bool hasNextPage(dynamic json) {
  final pagination = json is Map ? json['pagination'] : null;
  return pagination is Map && pagination['next'] != null;
}
