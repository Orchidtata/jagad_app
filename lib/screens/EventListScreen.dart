import 'package:flutter/material.dart';
import 'package:jagar/models/event_model.dart';
import 'package:jagar/providers/event_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({Key? key}) : super(key: key);

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  @override
  void initState() {
    super.initState();
    // Load events saat screen pertama kali dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EventProvider>(context, listen: false).fetchEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jagad Badung Events'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<EventProvider>(context, listen: false).fetchEvents();
            },
          ),
        ],
      ),
      body: Consumer<EventProvider>(
        builder: (context, eventProvider, child) {
          // Loading state
          if (eventProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Error state
          if (eventProvider.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Terjadi Kesalahan',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      eventProvider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => eventProvider.fetchEvents(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Empty state
          if (eventProvider.events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.event_busy,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada event',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => eventProvider.fetchEvents(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }

          // Success state - show list
          return RefreshIndicator(
            onRefresh: () => eventProvider.fetchEvents(),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: eventProvider.events.length,
              itemBuilder: (context, index) {
                final event = eventProvider.events[index];
                return EventCard(event: event);
              },
            ),
          );
        },
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  final Event event;

  const EventCard({Key? key, required this.event}) : super(key: key);

  String _formatDate(DateTime? date) {
    if (date == null) return 'Tanggal belum ditentukan';
    return DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(date);
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start == null) return 'Tanggal belum ditentukan';

    final startStr = DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(start);

    if (end == null) {
      return startStr;
    }

    final endStr = DateFormat('HH:mm', 'id_ID').format(end);
    return '$startStr - $endStr WIB';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Navigate ke detail screen (opsional)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailScreen(eventId: event.idEvent),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Image/Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: event.banner != null && event.banner!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          event.banner!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.event,
                              size: 40,
                              color: Colors.deepPurple,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.event,
                        size: 40,
                        color: Colors.deepPurple,
                      ),
              ),
              const SizedBox(width: 12),
              // Event Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.namaEvent,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (event.deskripsi != null &&
                        event.deskripsi!.isNotEmpty) ...[
                      Text(
                        event.deskripsi!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                    ],
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _formatDateRange(event.startTime, event.endTime),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (event.lokasi != null && event.lokasi!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.lokasi!,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EventDetailScreen extends StatefulWidget {
  final int eventId;

  const EventDetailScreen({Key? key, required this.eventId}) : super(key: key);

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  Event? _event;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEventDetail();
  }

  Future<void> _loadEventDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      final event = await eventProvider.fetchEventById(widget.eventId);

      setState(() {
        _event = event;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Tanggal belum ditentukan';
    return DateFormat('EEEE, dd MMMM yyyy\nHH:mm WIB', 'id_ID').format(date);
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start == null) return 'Tanggal belum ditentukan';

    final startDate = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(start);
    final startTimeStr = DateFormat('HH:mm', 'id_ID').format(start);

    if (end == null) {
      return '$startDate\n$startTimeStr WIB';
    }

    final endTimeStr = DateFormat('HH:mm', 'id_ID').format(end);
    return '$startDate\n$startTimeStr - $endTimeStr WIB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Event'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_errorMessage!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadEventDetail,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : _event == null
                  ? const Center(child: Text('Event tidak ditemukan'))
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Event Image
                          if (_event!.banner != null &&
                              _event!.banner!.isNotEmpty)
                            Image.network(
                              _event!.banner!,
                              width: double.infinity,
                              height: 250,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 250,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.event, size: 64),
                                );
                              },
                            )
                          else
                            Container(
                              height: 250,
                              color: Colors.deepPurple.shade100,
                              child: const Center(
                                child: Icon(Icons.event,
                                    size: 64, color: Colors.deepPurple),
                              ),
                            ),

                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title
                                Text(
                                  _event!.namaEvent,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Date
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.access_time,
                                        color: Colors.deepPurple),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _formatDateRange(
                                            _event!.startTime, _event!.endTime),
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Location
                                if (_event!.lokasi != null &&
                                    _event!.lokasi!.isNotEmpty) ...[
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.location_on,
                                          color: Colors.deepPurple),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _event!.lokasi!,
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                const Divider(),
                                const SizedBox(height: 16),

                                // Description
                                const Text(
                                  'Deskripsi',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _event!.deskripsi ?? 'Tidak ada deskripsi',
                                  style: const TextStyle(
                                      fontSize: 16, height: 1.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}
