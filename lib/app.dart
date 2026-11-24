import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/repositories/http_auth_repository.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/get_current_user.dart';
import 'features/auth/domain/usecases/login.dart';
import 'features/auth/domain/usecases/logout.dart';
import 'features/auth/domain/usecases/register.dart';
import 'features/auth/domain/usecases/restore_session.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/board/data/repositories/http_board_repository.dart';
import 'features/board/domain/usecases/add_note.dart';
import 'features/board/domain/usecases/delete_note.dart';
import 'features/board/domain/usecases/get_notes.dart';
import 'features/board/domain/usecases/pin_note.dart';
import 'features/board/domain/usecases/react_to_note.dart';
import 'features/board/presentation/pages/board_page.dart';
import 'features/chat/data/repositories/http_chat_repository.dart';
import 'features/chat/domain/usecases/get_messages.dart';
import 'features/chat/domain/usecases/send_message.dart';
import 'features/chat/presentation/pages/chat_page.dart';
import 'features/chores/data/repositories/http_chore_repository.dart';
import 'features/chores/domain/usecases/add_chore.dart';
import 'features/chores/domain/usecases/complete_chore.dart';
import 'features/chores/domain/usecases/get_chores.dart';
import 'features/chores/domain/usecases/get_points.dart';
import 'features/chores/presentation/pages/chores_page.dart';
import 'features/finances/data/repositories/http_finance_repository.dart';
import 'features/finances/domain/usecases/add_expense.dart';
import 'features/finances/domain/usecases/confirm_payment.dart';
import 'features/finances/domain/usecases/delete_expense.dart';
import 'features/finances/domain/usecases/edit_expense.dart';
import 'features/finances/domain/usecases/get_debts.dart';
import 'features/finances/domain/usecases/get_expenses.dart';
import 'features/finances/domain/usecases/notify_payment.dart';
import 'features/finances/presentation/pages/finances_page.dart';
import 'features/home/presentation/pages/home_shell.dart';
import 'features/house/data/repositories/http_house_repository.dart';
import 'features/house/domain/usecases/create_house.dart';
import 'features/house/domain/usecases/deactivate_house.dart';
import 'features/house/domain/usecases/expel_member.dart';
import 'features/house/domain/usecases/get_current_house.dart';
import 'features/house/domain/usecases/get_houses.dart';
import 'features/house/domain/usecases/join_house.dart';
import 'features/house/domain/usecases/leave_house.dart';
import 'features/house/domain/usecases/select_house.dart';
import 'features/house/domain/usecases/transfer_admin.dart';
import 'features/house/presentation/pages/house_admin_page.dart';
import 'features/profile/data/repositories/http_profile_repository.dart';
import 'features/profile/domain/usecases/delete_account.dart';
import 'features/profile/domain/usecases/edit_name.dart';
import 'features/profile/domain/usecases/get_profile.dart';
import 'features/profile/presentation/pages/profile_page.dart';

// Aqui se eligen los repositorios que usa la app
class RoomieHubApp extends StatelessWidget {
  // Los tests pasan un auth falso para no usar el backend
  RoomieHubApp({super.key, AuthRepository? auth})
      : _auth = auth ?? HttpAuthRepository(pushToken: _fcmToken, storage: const FlutterSecureStorage()),
        // Con el auth falso tampoco se guarda nada en el telefono
        _storage = auth == null ? const FlutterSecureStorage() : null;

  // Android 13 en adelante e iOS piden permiso y si lo niegan no hay token
  static Future<String?> _fcmToken() async {
    final settings = await FirebaseMessaging.instance.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) return null;
    /* shortcut getToken esta deprecado pero el backend usa tokens de registro
       si se cambia hay que cambiar los dos juntos */
    // ignore: deprecated_member_use
    return FirebaseMessaging.instance.getToken();
  }

  final AuthRepository _auth;
  final FlutterSecureStorage? _storage;
  late final _house = HttpHouseRepository(_auth, _storage);
  late final _board = HttpBoardRepository(_auth);
  late final _chores = HttpChoreRepository(_auth);
  late final _chat = HttpChatRepository(_auth);
  late final _finances = HttpFinanceRepository(_auth);
  late final _profile = HttpProfileRepository(_auth);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoomieHub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => SplashPage(restoreSession: RestoreSession(_auth)),
        AppRoutes.login: (_) => LoginPage(login: Login(_auth), register: Register(_auth)),
        AppRoutes.home: (_) => HomeShell(
              finances: (house) => FinancesPage(
                house: house,
                getExpenses: GetExpenses(_finances),
                addExpense: AddExpense(_finances),
                editExpense: EditExpense(_finances),
                deleteExpense: DeleteExpense(_finances),
                getDebts: GetDebts(_finances),
                notifyPayment: NotifyPayment(_finances),
                confirmPayment: ConfirmPayment(_finances),
                getCurrentUser: GetCurrentUser(_auth),
              ),
              board: (house) => BoardPage(
                houseId: house.id,
                isAdmin: house.isAdmin,
                getNotes: GetNotes(_board),
                addNote: AddNote(_board),
                pinNote: PinNote(_board),
                reactToNote: ReactToNote(_board),
                deleteNote: DeleteNote(_board),
              ),
              chores: (house) => ChoresPage(
                houseId: house.id,
                isAdmin: house.isAdmin,
                getChores: GetChores(_chores),
                addChore: AddChore(_chores),
                completeChore: CompleteChore(_chores),
                getPoints: GetPoints(_chores),
                getCurrentUser: GetCurrentUser(_auth),
              ),
              chat: (house) => ChatPage(
                houseId: house.id,
                getMessages: GetMessages(_chat),
                sendMessage: SendMessage(_chat),
                getCurrentUser: GetCurrentUser(_auth),
              ),
              profile: ProfilePage(
                getProfile: GetProfile(_profile),
                editName: EditName(_profile),
                deleteAccount: DeleteAccount(_profile),
                logout: Logout(_auth),
              ),
              getCurrentHouse: GetCurrentHouse(_house),
              leaveHouse: LeaveHouse(_house),
              getHouses: GetHouses(_house),
              selectHouse: SelectHouse(_house),
              joinHouse: JoinHouse(_house),
              createHouse: CreateHouse(_house),
              adminPage: (house) => HouseAdminPage(
                house: house,
                getCurrentHouse: GetCurrentHouse(_house),
                expelMember: ExpelMember(_house),
                transferAdmin: TransferAdmin(_house),
                deactivateHouse: DeactivateHouse(_house),
              ),
            ),
      },
    );
  }
}
