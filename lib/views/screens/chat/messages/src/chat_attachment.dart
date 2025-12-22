import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '/models/models.dart';
import '/theme/theme.dart';

class ChatAttachment extends StatelessWidget {
  final List<MessagesModel> messages;
  const ChatAttachment({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    final media = messages.media();
    final links = messages.links();
    final docs = messages.documents();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: _buildHeaderBar(context),
        body: TabBarView(
          children: [_MediaTab(media), _LinksTab(links), _DocsTab(docs)],
        ),
      ),
    );
  }
}

class _MediaTab extends StatelessWidget {
  final List<FileModel> media;

  const _MediaTab(this.media);

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) {
      return Center(
        child: Text(
          'No media found',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: media.length,
      itemBuilder: (_, index) {
        final file = media[index];

        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(imageUrl: file.url, fit: BoxFit.cover),
        );
      },
    );
  }
}

PreferredSizeWidget _buildHeaderBar(BuildContext context) {
  return AppBar(
    backgroundColor: AppColors.white,
    elevation: 1.0,
    shadowColor: AppColors.black12,
    automaticallyImplyLeading: false,
    foregroundColor: AppColors.black,
    leading: IconButton(
      onPressed: () {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
      icon: Icon(Icons.close, color: AppColors.black),
    ),
    title: Text(
      'Media & Links',
      style: Theme.of(context).textTheme.titleLarge!.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
      ),
    ),
    bottom: TabBar(
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.grey500,
      labelStyle: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
      unselectedLabelStyle: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.normal),
      indicatorColor: AppColors.primary,
      tabs: const [
        Tab(text: 'Media'),
        Tab(text: 'Links'),
        Tab(text: 'Docs'),
      ],
    ),
  );
}

class _LinksTab extends StatelessWidget {
  final List<String> links;
  const _LinksTab(this.links);

  @override
  Widget build(BuildContext context) {
    if (links.isEmpty) {
      return Center(
        child: Text(
          'No links found',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return ListView.separated(
      itemCount: links.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, index) {
        final url = links[index];

        return ListTile(
          leading: const Icon(Icons.link),
          title: Text(
            url,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: const Icon(Icons.open_in_new),
          onTap: () => launchUrl(Uri.parse(url)),
        );
      },
    );
  }
}

class _DocsTab extends StatelessWidget {
  final List<FileModel> docs;

  const _DocsTab(this.docs);

  @override
  Widget build(BuildContext context) {
    if (docs.isEmpty) {
      return Center(
        child: Text(
          'No documents found',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return ListView.separated(
      itemCount: docs.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, index) {
        final file = docs[index];

        return ListTile(
          leading: const Icon(Icons.insert_drive_file),
          title: Text(file.name, style: Theme.of(context).textTheme.bodySmall),
          subtitle: Text(
            '${file.size} KB',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: const Icon(Icons.download),
          onTap: () {
            // download or open file
          },
        );
      },
    );
  }
}

extension MessagesExtensions on List<MessagesModel> {
  List<FileModel> media() {
    return expand((msg) => msg.attachments)
        .where(
          (f) =>
              f.mimeType.startsWith('image/') ||
              f.mimeType.startsWith('video/'),
        )
        .toList();
  }

  List<String> links() {
    final regex = RegExp(r'(https?:\/\/[^\s]+)', caseSensitive: false);

    final List<String> result = [];

    for (final msg in this) {
      final matches = regex.allMatches(msg.message);
      for (final match in matches) {
        final url = match.group(0);
        if (url != null) result.add(url);
      }
    }
    return result;
  }

  List<FileModel> documents() {
    return expand((msg) => msg.attachments)
        .where(
          (f) =>
              !f.mimeType.startsWith('image/') &&
              !f.mimeType.startsWith('video/') &&
              f.mimeType != 'link',
        )
        .toList();
  }
}
