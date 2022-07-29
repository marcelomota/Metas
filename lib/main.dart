import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List _toDoList = [];
  final _todoController = new TextEditingController();

  Map<String, dynamic> _lastRemoved = new Map();
  int _lastPos;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //carrega os dados com o future e depois atualiza com o setdata
    _readData().then((value) {
      setState(() {
        _toDoList = json.decode(value);
      });
    });
  }

  //função responsável por adicionar dinamicamente as tarefas na lista
  void _addTodo() {
    //para lidar com JSON
    setState(() {
      Map<String, dynamic> newTarefa = Map();
      newTarefa["title"] = _todoController.text;
      _todoController.text = "";
      newTarefa["ok"] = false;
      _toDoList.add(newTarefa);
    });
    _saveData();
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 2));
    setState(() {
      //atualiza a tela após a ordenação
      _toDoList.sort((a, b) {
        //metódo de ordenação
        if (a["ok"] && !b["ok"])
          return 1;
        else if (!a["ok"] && b["ok"])
          return -1;
        else
          return 0;
      });
      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("METAS"),
        backgroundColor: Colors.red,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                    child: TextField(
                  controller: _todoController,
                  decoration: InputDecoration(
                      labelText: "Nova Tarefa",
                      labelStyle: TextStyle(color: Colors.red)),
                )),
                IconButton(
                    icon: Icon(Icons.add_circle),
                    onPressed: _addTodo,
                    color: Colors.red)
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                    padding: EdgeInsets.only(top: 10.0),
                    itemCount: _toDoList.length,
                    itemBuilder: buildItem)),
          )
        ],
      ),
    );
  }

  Widget buildItem(BuildContext context, int index) {
    //widget que possibilita clicar e arrastar
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      //container utilizado para manipular dentro do widget as configurações como cor, alinhamento etc
      background: Container(
        color: Colors.grey,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white24,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          //pra trocar o icone maior da esquerda do app
          child:
              Icon(_toDoList[index]["ok"] ? Icons.done : Icons.horizontal_rule),
        ),
        onChanged: (check) {
          //set state atualiza o estado de toDo list
          setState(() {
            _toDoList[index]["ok"] = check;
            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        //atualiza as informações, armazena a ultima informação removida e guarda para remover de fato.
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastPos = index;
          _toDoList.removeAt(index);
          _saveData();
          //caixinha de aviso sobre a ação que foi removida
          final snackBar = SnackBar(
            content: Text("Tarefa ${_lastRemoved["title"]} removida"),
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: () {
                setState(() {
                  _toDoList.insert(_lastPos, _lastRemoved);
                  _saveData();
                });
              },
            ),
            duration: Duration(seconds: 3),
          );
          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snackBar);
        });
      },
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return Future.error(e);
    }
  }
}
