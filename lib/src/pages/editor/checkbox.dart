(String, int) insertCheckboxAtPoint(String text, int pos) {
  var start = text.lastIndexOf('\n', pos > 0 ? pos - 1 : 0) + 1;
  if (start < 0) start = 0;
  var end = text.indexOf('\n', pos);
  if (end < 0) end = text.length;

  final lines = text.split('\n');
  final lineIndex = text.substring(0, start).split('\n').length - 1;
  final currentLine = lines[lineIndex];
  final info = _ListItemInfo.parse(currentLine);
  final indentation = info.indentation;

  if (currentLine.trim().isEmpty) {
    // Case 1: Empty line - potentially continue list from previous line
    var newMarker = '-';
    if (lineIndex > 0) {
      final prevInfo = _ListItemInfo.parse(lines[lineIndex - 1]);
      if (indentation == prevInfo.indentation) {
        newMarker = _getNextMarker(prevInfo.marker);
      }
    }
    final newLine = '$indentation$newMarker [ ] ';
    final newText = text.substring(0, start) + newLine + text.substring(end);
    final newOffset = start + newLine.length;
    return (newText, newOffset);
  } else if (info.marker != null) {
    final marker = info.marker!; // Promote marker to String since it's not null
    if (info.checkbox != null) {
      // Case 2: List item with checkbox - insert new item below
      final nextMarker = _getNextMarker(marker);
      final newLine = '$indentation$nextMarker [ ] ';
      final newText =
          '${text.substring(0, end)}\n$newLine${text.substring(end)}';
      final newOffset = end + 1 + newLine.length;
      return (newText, newOffset);
    } else {
      // Case 3: List item without checkbox - add checkbox inline
      final newContent = '$indentation$marker [ ] ${info.content.trim()}';
      final newText =
          text.substring(0, start) + newContent + text.substring(end);
      final newOffset = start + newContent.length;
      return (newText, newOffset);
    }
  } else {
    // Case 4: Non-list item - convert to list item with checkbox
    final newContent = '$indentation- [ ] ${info.content.trim()}';
    final newText = text.substring(0, start) + newContent + text.substring(end);
    final newOffset = start + newContent.length;
    return (newText, newOffset);
  }
}

(String, int)? insertCheckboxOverRange(String text, int start, int end) {
  final rangeText = text.substring(start, end);
  final lines = rangeText.split('\n');
  final transformedLines = <String>[];

  for (final line in lines) {
    final info = _ListItemInfo.parse(line);
    final indentation = info.indentation;
    if (info.marker != null && info.checkbox == null) {
      final marker = info.marker!; // Promote marker to String
      // Add checkbox to list items without one
      final newContent = '$indentation$marker [ ] ${info.content.trim()}';
      transformedLines.add(newContent);
    } else if (info.marker == null) {
      // Convert non-list items to list items with checkbox
      final newContent = '$indentation- [ ] ${info.content.trim()}';
      transformedLines.add(newContent);
    } else {
      // Leave lines with existing checkboxes unchanged
      transformedLines.add(line);
    }
  }

  // Join transformed lines and replace the selected range
  final transformedText = transformedLines.join('\n');
  final newText = text.replaceRange(start, end, transformedText);
  final newOffset = start + transformedText.length;
  return (newText, newOffset);
}

// Helper class to hold list item information
class _ListItemInfo {
  // Parse a line into its list item components
  factory _ListItemInfo.parse(String line) {
    final match = _listPattern.firstMatch(line);
    if (match != null) {
      final indentation = match.group(1)!;
      final marker = match.group(2);
      final checkbox = match.group(3);
      final content = match.group(4)!;
      return _ListItemInfo(indentation, marker, checkbox, content);
    }
    return _ListItemInfo('', null, null, line);
  }

  final String indentation;
  final String? marker; // e.g., "-", "+", "*", "1.", "1)"
  final String? checkbox; // "[ ]" or "[X]"
  final String content;

  String get markerOrDefault => marker ?? '-';

  _ListItemInfo(this.indentation, this.marker, this.checkbox, this.content);
}

final _listPattern = RegExp(r'^(\s*)([-\+\*]|\d+[\.\)])?\s*(\[.\])?\s*(.*)$');

final _numPattern = RegExp(r'(\d+)([\.\)])');

// Generate the next marker for ordered lists
String _getNextMarker(String? marker) {
  if (marker == null) return '-';
  final match = _numPattern.firstMatch(marker);
  if (match != null) {
    final num = int.parse(match.group(1)!);
    final suffix = match.group(2)!;
    return '${num + 1}$suffix';
  }
  return marker; // Return same marker for unordered lists
}
