import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(ProductA());
}

class ProductA extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Магазин товаров',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  List<Product> products = [];
  String jsonPath = '';

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<String> getJsonFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/data.json';
  }

  Future<void> loadProducts() async {
    jsonPath = await getJsonFilePath();
    if (File(jsonPath).existsSync()) {
      final String response = await File(jsonPath).readAsString();
      final List<dynamic> data = json.decode(response);
      setState(() {
        products = data.map((json) => Product.fromJson(json)).toList();
      });
      _loadFavorites();
    } else {
      File(jsonPath).writeAsString('[]');
    }
  }

  Future<void> saveProductsToFile() async {
    final file = File(jsonPath);
    final List<Map<String, dynamic>> jsonProducts = products.map((p) => p.toJson()).toList();
    await file.writeAsString(json.encode(jsonProducts));
  }

  Future<void> _loadFavorites() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? favoriteIds = prefs.getStringList('favorites');
    if (favoriteIds != null) {
      setState(() {
        for (var product in products) {
          product.isFavorite = favoriteIds.contains(product.id.toString());
        }
      });
    }
  }

  Future<void> _saveFavorites() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favoriteIds = products.where((product) => product.isFavorite).map((product) => product.id.toString()).toList();
    prefs.setStringList('favorites', favoriteIds);
  }

  void _toggleFavorite(Product product) {
    setState(() {
      product.isFavorite = !product.isFavorite;
      _saveFavorites();
      saveProductsToFile(); // Save changes after toggling
    });
  }

  void _addProduct(Product product) {
    setState(() {
      products.add(product);
      saveProductsToFile();
    });
  }

  void _deleteProduct(Product product) {
    setState(() {
      products.remove(product);
      saveProductsToFile(); // Save changes after deletion
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> _pages = [
      ProductListPage(onFavoriteToggle: _toggleFavorite, products: products, onDelete: _deleteProduct),
      FavoritePage(
        favorites: products.where((product) => product.isFavorite).toList(),
        onFavoriteToggle: _toggleFavorite,
      ),
      ProfilePage(),
    ];

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Главная',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Избранное',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddProductPage(
                onProductAdded: _addProduct,
                nextId: products.isNotEmpty ? products.last.id + 1 : 1,
              ),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class Product {
  final int id;
  final String name;
  final String description;
  final String image;
  bool isFavorite;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    this.isFavorite = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      image: json['image'],
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
      'isFavorite': isFavorite,
    };
  }

  @override
  bool operator ==(other) {
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class ProductListPage extends StatelessWidget {
  final Function(Product) onFavoriteToggle;
  final List<Product> products;
  final Function(Product) onDelete;

  ProductListPage({required this.onFavoriteToggle, required this.products, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Список товаров'),
      ),
      body: products.isEmpty
          ? Center(child: CircularProgressIndicator())
          : GridView.builder(
        padding: EdgeInsets.all(0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 0,
          mainAxisSpacing: 10,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailPage(
                    product: product,
                    onDelete: () => onDelete(product),
                    onFavoriteToggle: onFavoriteToggle,
                  ),
                ),
              );
            },
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.blue,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Image.asset(
                          product.image,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(product.name),
                      IconButton(
                        icon: Icon(
                          product.isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: product.isFavorite ? Colors.red : Colors.grey,
                        ),
                        onPressed: () {
                          onFavoriteToggle(product);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class AddProductPage extends StatelessWidget {
  final Function(Product) onProductAdded;
  final int nextId;

  AddProductPage({required this.onProductAdded, required this.nextId});

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController imageController = TextEditingController();

  void saveProduct(BuildContext context) {
    final String name = nameController.text;
    final String description = descriptionController.text;
    final String image = imageController.text;

    if (name.isNotEmpty && description.isNotEmpty && image.isNotEmpty) {
      final newProduct = Product(
        id: nextId,
        name: name,
        description: description,
        image: image,
      );
      onProductAdded(newProduct);
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Заполните все поля')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Добавить товар'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Название:', style: TextStyle(fontSize: 16)),
            TextField(controller: nameController),
            SizedBox(height: 10),
            Text('Описание:', style: TextStyle(fontSize: 16)),
            TextField(controller: descriptionController),
            SizedBox(height: 10),
            Text('Изображение (путь к файлу):', style: TextStyle(fontSize: 16)),
            TextField(controller: imageController),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => saveProduct(context),
              child: Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductDetailPage extends StatelessWidget {
  final Product product;
  final VoidCallback onDelete;
  final Function(Product) onFavoriteToggle;

  ProductDetailPage({required this.product, required this.onDelete, required this.onFavoriteToggle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          IconButton(
            icon: Icon(product.isFavorite ? Icons.favorite : Icons.favorite_border, color: product.isFavorite ? Colors.red : Colors.grey),
            onPressed: () {
              onFavoriteToggle(product);
            },
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Удалить товар'),
                    content: Text('Вы уверены, что хотите удалить этот товар?'),
                    actions: [
                      TextButton(
                        child: Text('Отмена'),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      TextButton(
                        child: Text('Удалить'),
                        onPressed: () {
                          onDelete();
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(product.image, fit: BoxFit.cover),
            SizedBox(height: 16),
            Text(product.name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(product.description),
          ],
        ),
      ),
    );
  }
}

class FavoritePage extends StatelessWidget {
  final List<Product> favorites;
  final Function(Product) onFavoriteToggle;

  FavoritePage({required this.favorites, required this.onFavoriteToggle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Избранное'),
      ),
      body: favorites.isEmpty
          ? Center(child: Text('Нет избранных товаров'))
          : GridView.builder(
        padding: EdgeInsets.all(10),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 5,
          mainAxisSpacing: 5,
          childAspectRatio: (MediaQuery.of(context).size.width / 5) / (MediaQuery.of(context).size.height / 8),
        ),
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          final product = favorites[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailPage(
                    product: product,
                    onDelete: () {
                      // Handle deletion here (if needed)
                    },
                    onFavoriteToggle: onFavoriteToggle,
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.blue,
                  width: 2.0,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Image.asset(
                      product.image,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(product.name),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Профиль'),
      ),
      body: Center(
        child: Text('Информация о пользователе'),
      ),
    );
  }
}
