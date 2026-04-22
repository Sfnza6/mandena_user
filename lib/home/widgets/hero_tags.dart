import 'package:mandena/data/models/item.dart';

String itemHeroTag({required dynamic id, String? imageUrl, String? name, required int extra, required String scope}) {
  final intId = int.tryParse('${id ?? 0}') ?? 0;
  if (intId > 0) return 'item-hero-$intId';

  final img = (imageUrl ?? '').trim();
  if (img.isNotEmpty) return 'item-hero-img-$img';

  final n = (name ?? '').trim();
  if (n.isNotEmpty) return 'item-hero-name-$n';

  return 'item-hero-fallback';
}

String itemHeroTagScoped({
  required dynamic id,
  String? imageUrl,
  String? name,
  String? scope,
  Object? extra,
}) {
  final base = itemHeroTag(id: id, imageUrl: imageUrl, name: name, extra: 0, scope: '');
  final cleanScope = ((scope ?? 'default').trim().isEmpty)
      ? 'default'
      : (scope ?? 'default').trim();
  final extraPart = extra == null ? '' : '-${extra.toString()}';
  return '$base-$cleanScope$extraPart';
}

String itemHeroTagFromModel(ItemModel item, {String? scope, Object? extra}) =>
    itemHeroTagScoped(
      id: item.id,
      imageUrl: item.imageUrl,
      name: item.name,
      scope: scope,
      extra: extra,
    );

String itemHeroTagFromMap(
  Map<String, dynamic> map, {
  String? scope,
  Object? extra,
}) => itemHeroTagScoped(
  id: map['id'] ?? map['item_id'] ?? map['itemId'],
  imageUrl: (map['image_url'] ?? map['imageUrl'] ?? map['image'] ?? '')
      .toString(),
  name: (map['name'] ?? '').toString(),
  scope: scope,
  extra: extra,
);

Map<String, dynamic> withItemHeroArg(
  Map<String, dynamic> data,
  String heroTag,
) {
  final map = Map<String, dynamic>.from(data);
  map['_heroTag'] = heroTag;
  return map;
}
