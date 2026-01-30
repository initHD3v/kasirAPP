
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:kasir_app/src/data/models/user_model.dart';
import 'package:kasir_app/src/data/repositories/user_repository.dart';

part 'user_event.dart';
part 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository _userRepository;

  UserBloc(this._userRepository) : super(UsersInitial()) {
    on<LoadUsers>(_onLoadUsers);
    on<AddUser>(_onAddUser);
    on<UpdateUser>(_onUpdateUser);
    on<DeleteUser>(_onDeleteUser);
  }

  void _onLoadUsers(LoadUsers event, Emitter<UserState> emit) async {
    emit(UsersLoading());
    try {
      final users = await _userRepository.getUsers();
      emit(UsersLoaded(users));
    } catch (e) {
      emit(UserOperationFailure(e.toString()));
    }
  }

  void _onAddUser(AddUser event, Emitter<UserState> emit) async {
    try {
      await _userRepository.addUser(event.username, event.password, event.role);
      add(LoadUsers()); // Muat ulang daftar pengguna setelah berhasil menambah
    } catch (e) {
      // Jika terjadi error (misal: username sudah ada), kita emit state error
      // agar bisa ditampilkan di UI
      emit(UserOperationFailure(e.toString()));
      // Kemudian load ulang list user agar UI kembali ke state normal
      add(LoadUsers());
    }
  }

  void _onUpdateUser(UpdateUser event, Emitter<UserState> emit) async {
    try {
      await _userRepository.updateUser(event.user, newPassword: event.password);
      add(LoadUsers());
    } catch (e) {
      emit(UserOperationFailure(e.toString()));
      add(LoadUsers());
    }
  }

  void _onDeleteUser(DeleteUser event, Emitter<UserState> emit) async {
    try {
      await _userRepository.deleteUser(event.userId);
      add(LoadUsers());
    } catch (e) {
      emit(UserOperationFailure(e.toString()));
      add(LoadUsers());
    }
  }
}
