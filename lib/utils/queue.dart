// um tipo de fila que pode ser enfileirado de ambos os lados e desenfileirado de ambos os lados 
// haverá uma pilha pros vídeos anteriores e uma fila pros vídeos seguintes
// a fila precisa se adaptar dependendo da direção do scroll
// USUÁRIO DESCENDO: vídeo de cima é empilhado no topo da queue de anteriores e a fila de seguintes é dequeuada
// USUÁRIO SUBINDO: vídeo de baixo é empilhado na fila de seguintes e a pilha de anteriores é desempilhada
// VÍDEOS NOVOS DA API: são enfileirados na fila de seguintes
class Queue<T> {
  final List<T> _queue = [];

  void enqueueTail(T item) {
    _queue.add(item);
  }

  void enqueueHead(T item) {
    _queue.insert(0, item);
  }

  T dequeueTail() {
    return _queue.removeLast();
  }

  T dequeueHead() {
    return _queue.removeAt(0);
  }

  @override
  String toString() {
    String result = '';
    for (T item in _queue) {
      result += '$item\n';
    }
    return result;
  }

  int get length => _queue.length;

  T peekHead() {
    return _queue.first;
  }

  T peekTail() {
    return _queue.last;
  }

  bool isEmpty() {
    return _queue.isEmpty;
  }
}
