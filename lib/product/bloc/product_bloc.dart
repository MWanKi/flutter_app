import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutterapp/authentication_bloc/authentication_bloc.dart';
import 'package:flutterapp/model/product.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

import 'bloc.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final AuthenticationBloc _authenticationBloc;

  ProductBloc({
    @required AuthenticationBloc authenticationBloc,
  })  : assert(authenticationBloc != null),
        _authenticationBloc = authenticationBloc;

  @override
  ProductState get initialState => ProductState.empty();

  @override
  Stream<Transition<ProductEvent, ProductState>> transformEvents(
    Stream<ProductEvent> events,
    TransitionFunction<ProductEvent, ProductState> transitionFn,
  ) {
    return super.transformEvents(
      events.debounceTime(const Duration(milliseconds: 400)),
      transitionFn,
    );
  }

  @override
  Stream<ProductState> mapEventToState(ProductEvent event) async* {
    if (event is ProductsLoad) {
      yield* _mapProductsLoadToState();
    }
  }

  Stream<ProductState> _mapProductsLoadToState() async* {
    if (!state.isLoading && !state.stateHasReachedMax) {
      yield state.updateLoading(isLoading: true);
      try {
        final response = await _authenticationBloc
            .get('/api/v1/product?page=${state.pageIndex + 1}');

        if (response != null) {
          final contents = response['content'] as List;
          final pageIndex = response['pageable']['pageNumber'];
          final last = response['last'];
          final List<Product> products = contents.map((data) {
            return Product.fromJson(data);
          }).toList();
          yield state.loaedSuccess(
            products:
                state.products != null ? state.products + products : products,
            pageIndex: pageIndex + 1,
            hasReachedMax: last,
          );
        }
      } catch (error) {
        print("]-----] error [-----[ ${error}");
        yield ProductState.failure();
      }
    }
  }
}
