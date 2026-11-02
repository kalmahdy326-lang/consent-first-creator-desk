import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(const CreatorDeskApp());

class Draft {
  Draft({required this.id, required this.title, this.body = '', this.aiDisclosure = false,
    this.audienceWarning = false, this.status = 'draft', this.revision = 1,
    this.approvedRevision, this.attachments = const []});
  final String id;
  String title;
  String body;
  bool aiDisclosure;
  bool audienceWarning;
  String status;
  int revision;
  int? approvedRevision;
  List<Map<String, String>> attachments;
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'body': body,
    'aiDisclosure': aiDisclosure, 'audienceWarning': audienceWarning, 'status': status,
    'revision': revision, 'approvedRevision': approvedRevision, 'attachments': attachments};
  factory Draft.fromJson(Map<String, dynamic> j) => Draft(
    id: j['id'] as String, title: j['title'] as String? ?? '', body: j['body'] as String? ?? '',
    aiDisclosure: j['aiDisclosure'] as bool? ?? false, audienceWarning: j['audienceWarning'] as bool? ?? false,
    status: j['status'] as String? ?? 'draft', revision: j['revision'] as int? ?? 1,
    approvedRevision: j['approvedRevision'] as int?,
    attachments: ((j['attachments'] as List?) ?? []).map((e) => Map<String, String>.from(e as Map)).toList());
}

class CreatorDeskApp extends StatelessWidget {
  const CreatorDeskApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(title: 'Consent-First Creator Desk',
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff345b66)), useMaterial3: true),
    home: const DeskHome());
}

class DeskHome extends StatefulWidget {
  const DeskHome({super.key});
  @override
  State<DeskHome> createState() => _DeskHomeState();
}

class _DeskHomeState extends State<DeskHome> {
  final List<Draft> drafts = [];
  final List<String> audit = [];
  bool killSwitch = false;
  bool loading = true;
  int tab = 0;
  Directory? dataDir;

  @override
  void initState() { super.initState(); _load(); }

  Future<File> _dataFile(String name) async {
    final base = dataDir ?? await getApplicationSupportDirectory();
    dataDir = base;
    await base.create(recursive: true);
    return File(base.path + Platform.pathSeparator + name);
  }

  Future<void> _load() async {
    try {
      final f = await _dataFile('creator_desk.json');
      if (await f.exists()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        drafts.addAll(((j['drafts'] as List?) ?? []).map((e) => Draft.fromJson(Map<String, dynamic>.from(e))));
        killSwitch = j['killSwitch'] as bool? ?? false;
        audit.addAll(((j['audit'] as List?) ?? []).cast<String>());
      }
    } catch (_) { audit.add('Could not read prior local data; starting with an empty view.'); }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _save() async {
    final f = await _dataFile('creator_desk.json');
    await f.writeAsString(jsonEncode({'drafts': drafts.map((d) => d.toJson()).toList(),
      'killSwitch': killSwitch, 'audit': audit}), flush: true);
  }

  void _log(String message) {
    audit.insert(0, DateTime.now().toIso8601String() + ' — ' + message);
    if (audit.length > 500) audit.removeRange(500, audit.length);
  }

  Future<void> _newDraft() async {
    if (killSwitch) return _notice('Kill switch is active. Turn it off to make changes.');
    final title = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('New draft'),
      content: TextField(controller: title, autofocus: true, decoration: const InputDecoration(labelText: 'Draft title')),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Create'))]));
    if (ok != true || title.text.trim().isEmpty) return;
    final d = Draft(id: DateTime.now().microsecondsSinceEpoch.toString(), title: title.text.trim());
    setState(() { drafts.insert(0, d); _log('Draft created: ' + d.title); });
    await _save();
    if (mounted) _editDraft(d);
  }

  Future<void> _editDraft(Draft d) async {
    if (killSwitch) return _notice('Kill switch is active. Turn it off to make changes.');
    final title = TextEditingController(text: d.title);
    final body = TextEditingController(text: d.body);
    final result = await showDialog<bool>(context: context, builder: (c) => StatefulBuilder(builder: (c, refresh) =>
      AlertDialog(title: const Text('Edit draft'),
        content: SizedBox(width: 520, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 12),
          TextField(controller: body, minLines: 4, maxLines: 10, decoration: const InputDecoration(labelText: 'Draft text')),
          const SizedBox(height: 8),
          SwitchListTile(value: d.aiDisclosure, onChanged: (v) => refresh(() => d.aiDisclosure = v),
            title: const Text('AI assistance disclosed'), contentPadding: EdgeInsets.zero),
          SwitchListTile(value: d.audienceWarning, onChanged: (v) => refresh(() => d.audienceWarning = v),
            title: const Text('Audience warning reviewed'), contentPadding: EdgeInsets.zero),
          Align(alignment: Alignment.centerLeft, child: Text('Images attached: ' + d.attachments.length.toString())),
          Align(alignment: Alignment.centerLeft, child: TextButton.icon(
            onPressed: () async { await _importImage(d); refresh(() {}); },
            icon: const Icon(Icons.add_photo_alternate_outlined), label: const Text('Import image (adult confirmation required)'))),
          ...d.attachments.map((a) => ListTile(dense: true, leading: const Icon(Icons.image_outlined),
            title: Text(a['name'] ?? 'Image'), subtitle: Text('Provenance: ' + (a['provenance'] ?? '')))),
        ]))),
        actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Save draft'))])));
    if (result != true) return;
    setState(() {
      d.title = title.text.trim(); d.body = body.text; d.revision++;
      d.status = 'draft'; d.approvedRevision = null;
      _log('Draft edited; review and approval invalidated: ' + d.title);
    });
    await _save();
  }

  Future<void> _importImage(Draft d) async {
    if (killSwitch) return _notice('Kill switch is active.');
    final confirmed = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('Adult-content safety confirmation'),
      content: const Text('Confirm before each import: I am an adult, the depicted person is clearly an adult, and the material is consensual. Do not import youth-looking, non-consensual, or unlawfully obtained material.'),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('I confirm'))]));
    if (confirmed != true) return;
    final picked = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false, withData: false);
    if (picked == null || picked.files.isEmpty) return;
    final provenance = TextEditingController();
    final entered = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('Image provenance'),
      content: TextField(controller: provenance, autofocus: true, minLines: 2, maxLines: 4,
        decoration: const InputDecoration(labelText: 'Source, rights/permission basis, and notes', hintText: 'Required before review')),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Save provenance'))]));
    if (entered != true || provenance.text.trim().isEmpty) return _notice('Image not imported: provenance is required.');
    final path = picked.files.single.path;
    if (path == null) return _notice('Could not access the selected file.');
    final placeholder = await _dataFile('placeholder.txt');
    final mediaDir = Directory(placeholder.parent.path + Platform.pathSeparator + 'media');
    await mediaDir.create(recursive: true);
    final safeName = picked.files.single.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final name = DateTime.now().microsecondsSinceEpoch.toString() + '_' + safeName;
    final copied = await File(path).copy(mediaDir.path + Platform.pathSeparator + name);
    setState(() {
      d.attachments = [...d.attachments, {'name': picked.files.single.name, 'path': copied.path, 'provenance': provenance.text.trim()}];
      d.revision++; d.status = 'draft'; d.approvedRevision = null;
      _log('Image imported with provenance: ' + picked.files.single.name);
    });
    await _save();
  }

  Future<void> _ready(Draft d) async {
    if (killSwitch) return _notice('Kill switch is active.');
    if (d.title.trim().isEmpty || d.body.trim().isEmpty || !d.aiDisclosure || !d.audienceWarning ||
        d.attachments.any((a) => (a['provenance'] ?? '').trim().isEmpty)) {
      return _notice('Before review: add a title and draft text, confirm AI disclosure and audience warning, and ensure every image has provenance.');
    }
    setState(() { d.status = 'readyForReview'; d.approvedRevision = null; _log('Draft queued for owner review: ' + d.title); });
    await _save();
    _notice('Draft is ready for owner review. Nothing has been published.');
  }

  Future<void> _approve(Draft d) async {
    if (killSwitch) return _notice('Kill switch is active.');
    final yes = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('Owner approval'),
      content: const Text('Approve this exact revision for manual owner publishing? This app will not publish it for you.'),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Approve revision'))]));
    if (yes != true) return;
    setState(() { d.status = 'approved'; d.approvedRevision = d.revision; _log('Owner approved revision ' + d.revision.toString() + ': ' + d.title); });
    await _save();
  }

  Future<void> _notice(String text) async {
    if (!mounted) return;
    await showDialog<void>(context: context, builder: (c) => AlertDialog(content: Text(text),
      actions: [FilledButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))]));
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final visible = tab == 1 ? drafts.where((d) => d.status == 'readyForReview').toList() : drafts;
    return Scaffold(appBar: AppBar(title: const Text('Consent-First Creator Desk'),
      actions: [IconButton(tooltip: 'New draft', onPressed: _newDraft, icon: const Icon(Icons.add))]),
      body: Column(children: [
        MaterialBanner(backgroundColor: killSwitch ? Theme.of(context).colorScheme.errorContainer : Theme.of(context).colorScheme.surfaceContainerHighest,
          leading: Icon(killSwitch ? Icons.pause_circle_filled : Icons.shield_outlined),
          content: Text(killSwitch ? 'KILL SWITCH ACTIVE — changes and approvals are blocked.' : 'Local-only drafting. Nothing is published automatically.'),
          actions: [TextButton(onPressed: () async {
            setState(() { killSwitch = !killSwitch; _log(killSwitch ? 'Kill switch enabled' : 'Kill switch disabled'); });
            await _save();
          }, child: Text(killSwitch ? 'Turn off' : 'Activate'))]),
        Expanded(child: tab == 2 ? _settings() : tab == 3 ? _auditView() : visible.isEmpty
          ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(tab == 1 ? 'No drafts are waiting for review.' : 'No drafts yet. Tap + to create one.')))
          : ListView.builder(itemCount: visible.length, itemBuilder: (c, i) {
            final d = visible[i];
            return Card(margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: ListTile(
              leading: Icon(d.status == 'approved' ? Icons.verified_outlined : d.status == 'readyForReview' ? Icons.rate_review_outlined : Icons.edit_note),
              title: Text(d.title.isEmpty ? '(Untitled draft)' : d.title),
              subtitle: Text(d.status + ' • revision ' + d.revision.toString() + ' • ' + d.attachments.length.toString() + ' image(s)'),
              onTap: () => _editDraft(d),
              trailing: PopupMenuButton<String>(onSelected: (v) => v == 'edit' ? _editDraft(d) : _ready(d),
                itemBuilder: (_) => [const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  if (d.status != 'approved') const PopupMenuItem(value: 'ready', child: Text('Submit for review'))])));
          })),
      ]),
      floatingActionButton: tab < 2 ? FloatingActionButton.extended(onPressed: _newDraft, icon: const Icon(Icons.add), label: const Text('New draft')) : null,
      bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [NavigationDestination(icon: Icon(Icons.folder_outlined), selectedIcon: Icon(Icons.folder), label: 'Drafts'),
          NavigationDestination(icon: Icon(Icons.rate_review_outlined), label: 'Review'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Audit')]));
  }

  Widget _settings() => ListView(padding: const EdgeInsets.all(16), children: [
    const Text('Safety and privacy', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    const ListTile(leading: Icon(Icons.cloud_off_outlined), title: Text('Offline core'),
      subtitle: Text('No API client, authentication service, scheduler, social posting, payments, or network publishing is included.')),
    const ListTile(leading: Icon(Icons.person_outline), title: Text('Human owner controls approval'),
      subtitle: Text('Approval is recorded against the current revision. Editing invalidates previous approval.')),
    const ListTile(leading: Icon(Icons.folder_open_outlined), title: Text('Local storage'),
      subtitle: Text('Draft data and imported images are stored in this device user profile. Protect the device and backups.')),
    SwitchListTile(value: killSwitch, onChanged: (v) async {
      setState(() { killSwitch = v; _log(v ? 'Kill switch enabled' : 'Kill switch disabled'); }); await _save();
    }, title: const Text('Persistent kill switch'), subtitle: const Text('Blocks editing, imports, review submission, and approval while active.')),
    const ListTile(leading: Icon(Icons.warning_amber_outlined), title: Text('Not a publishing tool'),
      subtitle: Text('Review and approval do not post content anywhere. The owner must publish manually outside this app.')),
  ]);

  Widget _auditView() => ListView(padding: const EdgeInsets.all(16), children: [
    const Text('Local audit log', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    if (audit.isEmpty) const Text('No events recorded yet.'),
    ...audit.map((entry) => ListTile(dense: true, leading: const Icon(Icons.receipt_long_outlined), title: Text(entry))),
  ]);
}
