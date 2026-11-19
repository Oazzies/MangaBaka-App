/// These endpoints report `pagination.next`; `pagination.count` only sometimes.
class PagedList<T> {
  final List<T> items;
  final bool hasNext;
  final int? total;

  const PagedList(this.items, {required this.hasNext, this.total});
}

bool hasNextPage(dynamic json) {
  final pagination = json is Map ? json['pagination'] : null;
  return pagination is Map && pagination['next'] != null;
}
