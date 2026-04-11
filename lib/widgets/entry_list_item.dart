import 'package:flutter/material.dart';

class EntryListItem extends StatelessWidget {

  final String coverUrl;
  final String title;

  const EntryListItem({
    Key? key,
    required this.coverUrl,
    required this.title,
  }) : super(key : key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: 120,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.horizontal(left: Radius.circular(8)),
              child: Image.network(
                coverUrl,
                width: 80,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              )
            ),
          ],
        )
      )
    );
  }
}