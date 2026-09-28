import 'package:flutter/foundation.dart';

import '../data/database/app_database.dart';
import '../repositories/asset_repository.dart';

class AssetProvider extends ChangeNotifier {
  AssetProvider(this._repository);

  final AssetRepository _repository;

  List<Asset> _assets = [];
  bool _isLoading = false;
  String? _errorMessage;

  String _searchQuery = '';

  int? _categoryId;
  int? _locationId;
  String? _condition;
  String? _warrantyStatus;

  String _sortType = 'created_desc';

  List<Asset> get assets => List.unmodifiable(_assets);

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  String get searchQuery => _searchQuery;

  int? get categoryId => _categoryId;

  int? get locationId => _locationId;

  String? get condition => _condition;

  String? get warrantyStatus => _warrantyStatus;

  String get sortType => _sortType;

  Future<void> loadAssets() async {
    _setLoading(true);

    try {
      _errorMessage = null;
      _assets = await _repository.getAllAssets();
    } catch (error) {
      _errorMessage = 'ไม่สามารถโหลดทรัพย์สินได้';
      debugPrint('AssetProvider.loadAssets: $error');
    } finally {
      _setLoading(false);
    }
  }

  Future<Asset?> getAssetById(int id) async {
    try {
      return await _repository.getAssetById(id);
    } catch (error) {
      debugPrint('AssetProvider.getAssetById: $error');
      return null;
    }
  }

  Future<bool> addAsset(AssetsCompanion asset) async {
    _setLoading(true);

    try {
      _errorMessage = null;

      await _repository.insertAsset(asset);

      _assets = await _repository.getAllAssets();

      return true;
    } catch (error) {
      _errorMessage = _getAssetError(error);
      debugPrint('AssetProvider.addAsset: $error');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateAsset(AssetsCompanion asset) async {
    _setLoading(true);

    try {
      _errorMessage = null;

      final updated = await _repository.updateAsset(asset);

      if (!updated) {
        _errorMessage = 'ไม่สามารถแก้ไขทรัพย์สินได้';
        return false;
      }

      _assets = await _repository.getAllAssets();

      return true;
    } catch (error) {
      _errorMessage = _getAssetError(error);
      debugPrint('AssetProvider.updateAsset: $error');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteAsset(int id) async {
    _setLoading(true);

    try {
      _errorMessage = null;

      final deletedRows = await _repository.deleteAsset(id);

      if (deletedRows == 0) {
        _errorMessage = 'ไม่พบทรัพย์สินที่ต้องการลบ';
        return false;
      }

      _assets = await _repository.getAllAssets();

      return true;
    } catch (error) {
      _errorMessage = 'ไม่สามารถลบทรัพย์สินได้';
      debugPrint('AssetProvider.deleteAsset: $error');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  void setCategoryFilter(int? categoryId) {
    _categoryId = categoryId;
    notifyListeners();
  }

  void setLocationFilter(int? locationId) {
    _locationId = locationId;
    notifyListeners();
  }

  void setConditionFilter(String? condition) {
    _condition = condition;
    notifyListeners();
  }

  void setWarrantyFilter(String? warrantyStatus) {
    _warrantyStatus = warrantyStatus;
    notifyListeners();
  }

  void setSortType(String sortType) {
    _sortType = sortType;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _categoryId = null;
    _locationId = null;
    _condition = null;
    _warrantyStatus = null;
    _sortType = 'created_desc';

    notifyListeners();
  }

  List<Asset> get filteredAssets {
    var result = List<Asset>.from(_assets);

    if (_searchQuery.isNotEmpty) {
      result = result.where((asset) {
        final name = asset.name.toLowerCase();
        final description = asset.description?.toLowerCase() ?? '';
        final serialNumber =
            asset.serialNumber?.toLowerCase() ?? '';

        return name.contains(_searchQuery) ||
            description.contains(_searchQuery) ||
            serialNumber.contains(_searchQuery);
      }).toList();
    }

    if (_categoryId != null) {
      result = result
          .where((asset) => asset.categoryId == _categoryId)
          .toList();
    }

    if (_locationId != null) {
      result = result
          .where((asset) => asset.locationId == _locationId)
          .toList();
    }

    if (_condition != null) {
      result = result
          .where((asset) => asset.condition == _condition)
          .toList();
    }

    if (_warrantyStatus != null) {
      result = result
          .where((asset) => _getWarrantyStatus(asset) == _warrantyStatus)
          .toList();
    }

    _sortAssets(result);

    return result;
  }

  double get totalValue {
    return _assets.fold(
      0,
      (sum, asset) => sum + asset.purchasePrice,
    );
  }

  int get totalAssets => _assets.length;

  int get activeWarrantyCount {
    return _assets
        .where(
          (asset) => _getWarrantyStatus(asset) == 'active',
        )
        .length;
  }

  int get expiringWarrantyCount {
    return _assets
        .where(
          (asset) => _getWarrantyStatus(asset) == 'expiringSoon',
        )
        .length;
  }

  int get expiredWarrantyCount {
    return _assets
        .where(
          (asset) => _getWarrantyStatus(asset) == 'expired',
        )
        .length;
  }

  String getWarrantyStatus(Asset asset) {
    return _getWarrantyStatus(asset);
  }

  String _getWarrantyStatus(Asset asset) {
    final warrantyEndDate = asset.warrantyEndDate;

    if (warrantyEndDate == null) {
      return 'notSpecified';
    }

    final now = DateTime.now();

    if (warrantyEndDate.isBefore(now)) {
      return 'expired';
    }

    final difference = warrantyEndDate.difference(now).inDays;

    if (difference <= 30) {
      return 'expiringSoon';
    }

    return 'active';
  }

  void _sortAssets(List<Asset> assets) {
    switch (_sortType) {
      case 'name_asc':
        assets.sort(
          (a, b) => a.name.toLowerCase().compareTo(
                b.name.toLowerCase(),
              ),
        );

      case 'price_desc':
        assets.sort(
          (a, b) => b.purchasePrice.compareTo(a.purchasePrice),
        );

      case 'price_asc':
        assets.sort(
          (a, b) => a.purchasePrice.compareTo(b.purchasePrice),
        );

      case 'purchase_newest':
        assets.sort(
          (a, b) => _compareDates(
            b.purchaseDate,
            a.purchaseDate,
          ),
        );

      case 'purchase_oldest':
        assets.sort(
          (a, b) => _compareDates(
            a.purchaseDate,
            b.purchaseDate,
          ),
        );

      case 'created_desc':
        assets.sort(
          (a, b) => b.createdAt.compareTo(a.createdAt),
        );
    }
  }

  int _compareDates(DateTime? a, DateTime? b) {
    if (a == null && b == null) {
      return 0;
    }

    if (a == null) {
      return 1;
    }

    if (b == null) {
      return -1;
    }

    return a.compareTo(b);
  }

  String _getAssetError(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('unique') &&
        message.contains('serial')) {
      return 'Serial Number นี้ถูกใช้งานแล้ว';
    }

    if (message.contains('constraint')) {
      return 'ข้อมูลทรัพย์สินไม่ถูกต้อง';
    }

    return 'เกิดข้อผิดพลาดในการจัดการทรัพย์สิน';
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}