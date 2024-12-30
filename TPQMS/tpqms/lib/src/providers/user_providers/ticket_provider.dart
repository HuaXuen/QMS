// In ticket_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tpqms/services/common_services/ticket_service.dart';
import 'package:tpqms/services/common_services/user_service.dart';
import 'package:tpqms/services/firebase_services/firestore_service.dart';
import 'package:tpqms/src/model/ticket_model.dart';

// First, let's define an enum for our loading states
enum TicketLoadingState {
  initial, // When the provider first initializes
  loading, // While fetching data
  loaded, // When data is successfully loaded
  error, // When an error occurs
}

class TicketProvider extends ChangeNotifier {
  final TicketService _ticketService;
  final FirestoreService _firestoreService;
  final UserService _userService;

  TicketProvider(
      this._ticketService, this._firestoreService, this._userService) {
    // Automatically load ticket data when provider is initialized
    loadTicketData();
  }

  // State management variables
  TicketLoadingState _loadingState = TicketLoadingState.initial;
  TicketModel? _ticket;
  String? _errorMessage;

  // Getters for our state variables
  TicketLoadingState get loadingState => _loadingState;
  TicketModel? get ticket => _ticket;
  String? get errorMessage => _errorMessage;
  bool get hasTicket => _ticket != null;
  bool get isLoading => _loadingState == TicketLoadingState.loading;

  // Method to load ticket data
  Future<void> loadTicketData() async {
    try {
      _setLoadingState(TicketLoadingState.loading);

      // Get current user's ID
      final String? userId = await _userService.getCurrentUserUid();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final String? userPhoneNumber =
          await _userService.getCurrentUserPhoneNumber();
      if (userPhoneNumber == null) {
        throw Exception('User not authenticated');
      }

      // Add debug logging
      print('Current userId: $userId');
      print('Current userId: $userPhoneNumber');

      // Fetch ticket using existing method
      final ticket = await _ticketService.getTicketByUserId(userId);

      // Add debug logging
      print('Fetched ticket data: $ticket');

      _ticket = ticket;
      _setLoadingState(TicketLoadingState.loaded);
    } catch (e) {
      print('Error in loadTicketData: $e'); // Add error logging
      _handleError('Error loading ticket: ${e.toString()}');
    }
  }

  TicketModel _prepareTicketForBinding(TicketModel scannedTicket,
      String currentUserId, String currentUserPhoneNumber) {
    // Create a new TicketModel with updated userId and isValid status
    return TicketModel(
      ticketId: scannedTicket.ticketId,
      userId: currentUserId, // Set the current user's ID
      phoneNumber: currentUserPhoneNumber,
      purchaseTime: scannedTicket.purchaseTime,
      expirationTime: scannedTicket.expirationTime,
      isValid: false, // Set to false as ticket is now claimed
      price: scannedTicket.price,
      missedQueue: scannedTicket.missedQueue,
      ridesQueued: scannedTicket.ridesQueued,
    );
  }

  // Update the bindTicketToCurrentUser method
  Future<Map<String, dynamic>> bindTicketToCurrentUser(
      Map<String, dynamic> scannedTicketData) async {
    try {
      _setLoadingState(TicketLoadingState.loading);

      // 1. Parse and validate scanned ticket
      final scannedTicket = await _validateAndParseTicket(scannedTicketData);
      if (scannedTicket == null) {
        print('Failed to parse/validate ticket data');
        return {'success': false, 'message': 'Invalid ticket data'};
      }
      print('Parsed ticket: ${scannedTicket.toMap()}');

      // 2. Get current user's ID
      final currentUserId = await _userService.getCurrentUserUid();
      final currentUserPhoneNumber =
          await _userService.getCurrentUserPhoneNumber();
      print('Retrieved currentUserId: $currentUserId');

      if (currentUserId == null) {
        print('User authentication failed - no currentUserId');
        return {'success': false, 'message': 'User not authenticated'};
      }

      if (currentUserPhoneNumber == null) {
        print('User authentication failed - no phone number');
        return {'success': false, 'message': 'User not authenticated'};
      }

      // 3. Prepare the ticket for binding with updated userId and validity
      final ticketToSave = _prepareTicketForBinding(
          scannedTicket, currentUserId, currentUserPhoneNumber);
      print('Prepared ticket for saving: ${ticketToSave.toMap()}');

      // 4. Save the prepared ticket and update state
      await _ticketService.addTicket(ticketToSave);
      _ticket = ticketToSave;
      _setLoadingState(TicketLoadingState.loaded);

      return {
        'success': true,
        'message': 'Ticket successfully bound to your account'
      };
    } catch (e) {
      _handleError('Error binding ticket: ${e.toString()}');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Manual refresh method
  Future<void> refreshTicketData() async {
    await loadTicketData();
  }

  // Private helper methods
  void _setLoadingState(TicketLoadingState state) {
    _loadingState = state;
    if (state != TicketLoadingState.error) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  void _handleError(String message) {
    _errorMessage = message;
    _setLoadingState(TicketLoadingState.error);
  }

  Future<TicketModel?> _validateAndParseTicket(
      Map<String, dynamic> scannedTicketData) async {
    try {
      // Parse scanned data into ticket model
      final scannedTicket = TicketModel(
        ticketId: scannedTicketData['ticketId'].toString(),
        userId: scannedTicketData['userId'] ?? '',
        phoneNumber: scannedTicketData['phoneNumber'] ?? '',
        purchaseTime: DateTime.parse(scannedTicketData['purchaseTime']),
        expirationTime: DateTime.parse(scannedTicketData['expirationTime']),
        isValid: scannedTicketData['isValid'] ?? false,
        price: (scannedTicketData['price'] ?? 0).toDouble(),
        missedQueue: scannedTicketData['missedQueue'] ?? 0,
        ridesQueued: scannedTicketData['ridesQueued'] ?? 0,
      );
      print('Ticket prepared for saving: ${scannedTicket.toMap()}');

      // Validate ticket
      final existingTicket =
          await _ticketService.getTicket(scannedTicket.ticketId);
      if (existingTicket != null) {
        throw Exception('Ticket already bound to a user');
      }

      if (scannedTicket.expirationTime.isBefore(DateTime.now())) {
        throw Exception('Ticket has expired');
      }

      if (!scannedTicket.isValid) {
        throw Exception('Ticket is not valid');
      }

      return scannedTicket;
    } catch (e) {
      throw Exception('Validation failed: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    notifyListeners();
    super.dispose();
  }

  Future<void> reset() async {
    try {
      print('[TICKET-PROVIDER] Starting reset...');

      _loadingState = TicketLoadingState.initial;
      _ticket = null;
      _errorMessage = null;
      notifyListeners();

      print('[TICKET-PROVIDER] Reset completed');
    } catch (e) {
      print('[TICKET-PROVIDER] Error during reset: $e');
    }
  }
}
