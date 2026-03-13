import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:lunarage/setting_page.dart';
import 'package:lunarage/ad_manager.dart';
import 'package:lunarage/ad_banner_widget.dart';
import 'package:lunarage/my_web_view_controller.dart';
import 'package:lunarage/local_server.dart';
import 'package:lunarage/loading_screen.dart';
import 'package:lunarage/model.dart';
import 'package:lunarage/theme_color.dart';
import 'package:lunarage/main.dart';
import 'package:lunarage/parse_locale_tag.dart';
import 'package:lunarage/theme_mode_number.dart';

class MainHomePage extends StatefulWidget {
  const MainHomePage({super.key});
  @override
  State<MainHomePage> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage> {
  late AdManager _adManager;
  final MyWebViewController _myWebViewController = MyWebViewController();
  final LocalServer _localServer = LocalServer();
  late final WebViewController _webViewController;
  late final List<int> _yearList;
  late final List<DropdownMenuItem<int>> _yearDropdownItems;
  final List<int> _monthList = List<int>.generate(12, (index) => index + 1);
  late final List<DropdownMenuItem<int>> _monthDropdownItems;
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  //
  late ThemeColor _themeColor;
  bool _isReady = false;
  bool _isFirst = true;

  @override
  void initState() {
    super.initState();
    _initState();
  }

  void _initState() async {
    _adManager = AdManager();
    _yearList = _generateYearList();
    _yearDropdownItems = _yearList.map<DropdownMenuItem<int>>((int year) {
      return DropdownMenuItem<int>(
        value: year,
        child: Text(year.toString(),
          style: const TextStyle(color: Colors.white),
        ),
      );
    }).toList();
    _monthDropdownItems = _monthList.map<DropdownMenuItem<int>>((int month) {
      return DropdownMenuItem<int>(
        value: month,
        child: Text(
          month.toString(),
          style: const TextStyle(color: Colors.white),
        ),
      );
    }).toList();
    _webViewController = _myWebViewController.controller();
    await _localServer.start();
    _updateWebView();
    if (mounted) {
      setState(() {
        _isReady = true;
      });
    }
  }

  @override
  void dispose() {
    _adManager.dispose();
    _localServer.close();
    super.dispose();
  }

  void _updateWebView() async {
    String serverUrl = _localServer.url();
    await _webViewController.loadRequest(Uri.parse('${serverUrl}index.html?year=$_selectedYear&month=$_selectedMonth'));
  }

  List<int> _generateYearList() {
    int currentYear = DateTime.now().year;
    return List<int>.generate(161, (index) => currentYear - 80 + index);
  }
  void _incrementYear() {
    setState(() {
      if (_selectedYear < _yearList.last) {
        _selectedYear += 1;
      }
      _updateWebView();
    });
  }
  void _decrementYear() {
    setState(() {
      if (_selectedYear > _yearList.first) {
        _selectedYear -= 1;
      }
      _updateWebView();
    });
  }
  void _incrementMonth() {
    setState(() {
      if (_selectedMonth < 12) {
        _selectedMonth += 1;
      } else {
        if (_selectedYear < _yearList.last) {
          _selectedMonth = 1;
          _selectedYear += 1;
        }
      }
      _updateWebView();
    });
  }

  void _decrementMonth() {
    setState(() {
      if (_selectedMonth > 1) {
        _selectedMonth -= 1;
      } else {
        if (_selectedYear > _yearList.first) {
          _selectedMonth = 12;
          _selectedYear -= 1;
        }
      }
      _updateWebView();
    });
  }

  Future<void> _onOpenSetting() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SettingPage()),
    );
    if (!mounted) {
      return;
    }
    if (updated == true) {
      final mainState = context.findAncestorStateOfType<MainAppState>();
      if (mainState != null) {
        mainState
          ..themeMode = ThemeModeNumber.numberToThemeMode(Model.themeNumber)
          ..locale = parseLocaleTag(Model.languageCode)
          ..setState(() {});
      }
      _isFirst = true;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return Scaffold(
        body: LoadingScreen(),
      );
    }
    if (_isFirst) {
      _isFirst = false;
      _themeColor = ThemeColor(themeNumber: Model.themeNumber, context: context);
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: _themeColor.mainBackColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            color: _themeColor.mainForeColor,
            onPressed: _onOpenSetting,
          ),
          const SizedBox(width:10),
        ],
      ),
      body: SafeArea(
        child: Column(children:[
          Row(children:[
            Expanded(child: _selectYear()),
            Expanded(child: _selectMonth()),
          ]),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 0),
              child: Center(
                child: WebViewWidget(controller: _webViewController),
              ),
            )
          ),
        ])
      ),
      bottomNavigationBar: AdBannerWidget(adManager: _adManager),
    );
  }

  Widget _selectYear() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left),
          color: Colors.white,
          onPressed: _decrementYear,
        ),
        DropdownButton<int>(
          value: _selectedYear,
          onChanged: (int? newValue) {
            setState(() {
              _selectedYear = newValue!;
              _updateWebView();
            });
          },
          dropdownColor: Colors.grey[850],
          items: _yearDropdownItems,
        ),
        IconButton(
          icon: Icon(Icons.chevron_right),
          color: Colors.white,
          onPressed: _incrementYear,
        ),
      ],
    );
  }

  Widget _selectMonth() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left),
          color: Colors.white,
          onPressed: _decrementMonth,
        ),
        DropdownButton<int>(
          value: _selectedMonth,
          onChanged: (int? newValue) {
            setState(() {
              _selectedMonth = newValue!;
              _updateWebView();
            });
          },
          dropdownColor: Colors.grey[850],
          items: _monthDropdownItems,
        ),
        IconButton(
          icon: Icon(Icons.chevron_right),
          color: Colors.white,
          onPressed: _incrementMonth,
        ),
      ],
    );
  }
}
