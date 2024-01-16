import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class ShoppingItem {
  String name;
  String category;
  int quantity;
  bool isBought;

  ShoppingItem({
    required this.name,
    required this.category,
    required this.quantity,
    this.isBought = false,
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liste de courses',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ShoppingList(),
    );
  }
}

class ShoppingList extends StatefulWidget {
  @override
  _ShoppingListState createState() => _ShoppingListState();
}

class _ShoppingListState extends State<ShoppingList>
    with WidgetsBindingObserver {
  List<ShoppingItem> shoppingItems = [];
  final TextEditingController nameController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);
    _loadShoppingList();
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // L'application est en pause ou inactive, sauvegarder les données
      _saveShoppingList();
    }
  }

  _loadShoppingList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedItems = prefs.getStringList('shoppingList');

    if (savedItems != null) {
      setState(() {
        shoppingItems = savedItems.map((item) {
          List<String> parts = item.split(',');
          return ShoppingItem(
            name: parts[0],
            category: parts[1],
            quantity: int.parse(parts[2]),
            isBought: parts[3] == 'true',
          );
        }).toList();
      });
    }
  }

  _saveShoppingList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> itemsToSave = shoppingItems.map((item) {
      return '${item.name},${item.category},${item.quantity},${item.isBought}';
    }).toList();

    prefs.setStringList('shoppingList', itemsToSave);
  }

  _addItem() {
    setState(() {
      shoppingItems.add(
        ShoppingItem(
          name: nameController.text,
          category: categoryController.text,
          quantity: int.parse(quantityController.text),
        ),
      );
      _saveShoppingList();
      nameController.clear();
      categoryController.clear();
      quantityController.clear();
    });
  }

  _removeItem(int index) {
    setState(() {
      shoppingItems.removeAt(index);
      _saveShoppingList();
    });
  }

  _toggleBought(int index) {
    setState(() {
      shoppingItems[index].isBought = !shoppingItems[index].isBought;
      _saveShoppingList();
    });
  }

  _editItem(int index) async {
    final TextEditingController editedNameController =
        TextEditingController(text: shoppingItems[index].name);
    final TextEditingController editedCategoryController =
        TextEditingController(text: shoppingItems[index].category);
    final TextEditingController editedQuantityController =
        TextEditingController(text: shoppingItems[index].quantity.toString());

    final editedItem = await showDialog<ShoppingItem>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Modifier l\'article'),
          content: Column(
            children: [
              TextField(
                controller: editedNameController,
                decoration: InputDecoration(labelText: 'Nom de l\'article'),
              ),
              TextField(
                controller: editedCategoryController,
                decoration: InputDecoration(labelText: 'Catégorie'),
              ),
              TextField(
                controller: editedQuantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Quantité'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  shoppingItems[index].name = editedNameController.text;
                  shoppingItems[index].category = editedCategoryController.text;
                  shoppingItems[index].quantity =
                      int.parse(editedQuantityController.text);
                  _saveShoppingList();
                });
                Navigator.pop(context);
              },
              child: Text('Enregistrer'),
            ),
          ],
        );
      },
    );

    if (editedItem != null) {
      _saveShoppingList();
    }
  }

  _sortItems(bool byName) {
    setState(() {
      shoppingItems.sort((a, b) =>
          byName ? a.name.compareTo(b.name) : a.category.compareTo(b.category));
    });
    _saveShoppingList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Liste de courses'),
      ),
      body: Column(
        children: [
            
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              
              ElevatedButton(
                onPressed: () => _sortItems(true),
                child: Text('Trier par nom'),
              ),
              ElevatedButton(
                onPressed: () => _sortItems(false),
                child: Text('Trier par catégorie'),
              ),
            ],
          ),
          SizedBox(height: 20),
          Text('Tableau des opérations'),
          DataTable(
            columns: [
              DataColumn(label: Text('Nom')),
              DataColumn(label: Text('Quantité')),
              DataColumn(label: Text('Catégorie')),
              DataColumn(label: Text('Acheté')),
              DataColumn(label: Text('Opérations')),
            ],
            rows: shoppingItems
                .asMap()
                .entries
                .map((entry) => DataRow(
                      cells: [
                        DataCell(Text(entry.value.name)),
                        DataCell(Text(entry.value.quantity.toString())),
                        DataCell(Text(entry.value.category)),
                        DataCell(
                          Checkbox(
                            value: entry.value.isBought,
                            onChanged: (value) {
                              setState(() {
                                shoppingItems[entry.key].isBought = value!;
                                _saveShoppingList();
                              });
                            },
                          ),
                        ),
                        DataCell(Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () => _editItem(entry.key),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () => _removeItem(entry.key),
                            ),
                          ],
                        )),
                      ],
                    ))
                .toList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Ajouter un article'),
                content: Column(
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: 'Nom'),
                    ),
                    TextField(
                      controller: categoryController,
                      decoration: InputDecoration(labelText: 'Catégorie'),
                    ),
                    TextField(
                      controller: quantityController,
                      decoration: InputDecoration(labelText: 'Quantité'),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Annuler'),
                  ),
                  TextButton(
                    onPressed: () {
                      final newItem = ShoppingItem(
                        name: nameController.text,
                        category: categoryController.text,
                        quantity: int.parse(quantityController.text),
                      );
                      setState(() {
                        shoppingItems.add(newItem);
                        _saveShoppingList();
                      });
                      Navigator.pop(context);
                    },
                    child: Text('Ajouter'),
                  ),
                ],
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
