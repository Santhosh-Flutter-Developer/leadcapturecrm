import 'package:aaatp/services/firebase/firebase.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '/models/models.dart';
import '/views/views.dart';

class AttachmentColors {
  static const Color primary = Color(0xFF2563EB);
  static const Color background = Color(0xFFF8FAFC);
  static const Color white = Colors.white;
  static const Color border = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
}

class ChatAttachment extends StatefulWidget {
  final String chatId;
  const ChatAttachment({super.key, required this.chatId});

  @override
  State<ChatAttachment> createState() => _ChatAttachmentState();
}

class _ChatAttachmentState extends State<ChatAttachment> {
  List<MessagesModel> messages = [];
  List<FileModel> media = [];
  List<String> links = [];
  List<FileModel> docs = [];
  late Future _future;

  @override
  void initState() {
    _future = _init();
    super.initState();
  }

  Future _init() async {
    var messages = await ChatService.getChatMessages(uid: widget.chatId);
    media = messages.media();
    links = messages.links();
    docs = messages.documents();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AttachmentColors.background,
        appBar: AppBar(
          backgroundColor: AttachmentColors.white,
          elevation: 0,
          centerTitle: false,
          automaticallyImplyLeading: false,
          // leading: IconButton(
          //   onPressed: () => Navigator.pop(context),
          //   icon: const Icon(
          //     Iconsax.arrow_left,
          //     color: AttachmentColors.textPrimary,
          //     size: 20,
          //   ),
          // ),
          title: const Text(
            'Media & Assets',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AttachmentColors.textPrimary,
              fontSize: 18,
            ),
          ),
          bottom: TabBar(
            labelColor: AttachmentColors.primary,
            unselectedLabelColor: AttachmentColors.textSecondary,
            indicatorColor: AttachmentColors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: 'Media'),
              Tab(text: 'Links'),
              Tab(text: 'Docs'),
            ],
          ),
        ),
        body: FutureBuilder(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const WaitingLoading();
            } else if (snapshot.hasError) {
              return ErrorDisplay(error: snapshot.error.toString());
            } else {
              return TabBarView(
                children: [_MediaTab(media), _LinksTab(links), _DocsTab(docs)],
              );
            }
          },
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
      return _buildEmptyState(Iconsax.gallery, "No media shared yet");
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: media.length,
      itemBuilder: (_, index) {
        final file = media[index];
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AttachmentColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: CachedNetworkImage(
              imageUrl: file.url,
              fit: BoxFit.cover,
              placeholder: (context, url) => Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(color: Colors.white),
              ),
              errorWidget: (context, url, error) => Container(
                color: AttachmentColors.border,
                child: const Icon(
                  Iconsax.gallery_slash,
                  color: AttachmentColors.textSecondary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LinksTab extends StatelessWidget {
  final List<String> links;
  const _LinksTab(this.links);

  @override
  Widget build(BuildContext context) {
    if (links.isEmpty) {
      return _buildEmptyState(Iconsax.link, "No links found in chat");
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: links.length,
      itemBuilder: (_, index) {
        final url = links[index];
        final domain = Uri.parse(url).host;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AttachmentColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AttachmentColors.border),
          ),
          child: ListTile(
            onTap: () => launchUrl(Uri.parse(url)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AttachmentColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Iconsax.link_1,
                color: AttachmentColors.primary,
                size: 20,
              ),
            ),
            title: Text(
              url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AttachmentColors.textPrimary,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                domain.isEmpty ? "External Link" : domain,
                style: const TextStyle(
                  fontSize: 12,
                  color: AttachmentColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            trailing: const Icon(
              Iconsax.export_1,
              size: 18,
              color: AttachmentColors.textSecondary,
            ),
          ),
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
      return _buildEmptyState(Iconsax.document_text, "No documents attached");
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (_, index) {
        final file = docs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AttachmentColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AttachmentColors.border),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Iconsax.document_text,
                color: Colors.orangeAccent,
                size: 20,
              ),
            ),
            title: Text(
              file.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AttachmentColors.textPrimary,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${file.size} KB • ${file.extension.toUpperCase()}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AttachmentColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            trailing: const Icon(
              Iconsax.arrow_circle_down,
              size: 22,
              color: AttachmentColors.primary,
            ),
            onTap: () {
              // Trigger file download/viewing
            },
          ),
        );
      },
    );
  }
}

Widget _buildEmptyState(IconData icon, String message) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 48, color: AttachmentColors.border),
        const SizedBox(height: 16),
        Text(
          message,
          style: const TextStyle(
            color: AttachmentColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    ),
  );
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
