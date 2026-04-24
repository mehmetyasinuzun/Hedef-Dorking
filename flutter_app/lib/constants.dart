import 'package:flutter/material.dart';

const String kBackendUrl = 'http://localhost:8080';

const Map<String, Color> kKategoriRenkleri = {
  'Hedef Bazli':    Color(0xFFFF6B6B),
  'Dosya Tespiti':  Color(0xFF58A6FF),
  'Kimlik Bilgisi': Color(0xFFFFD93D),
  'Giris Panelleri':Color(0xFF6BCB77),
  'Acik Dizin':     Color(0xFFFF9F43),
  'Hata Mesajlari': Color(0xFFFF6B9D),
  'Kamera ve Cihaz':Color(0xFFC77DFF),
};

Color kategoriRenk(String kategori) =>
    kKategoriRenkleri[kategori] ?? const Color(0xFF8B949E);

// Renk paleti koleksiyon vb10 tarzı
const Color kArkaplan    = Color(0xFF0A0D14);
const Color kYuzey       = Color(0xFF0D1117);
const Color kKart        = Color(0xFF131820);
const Color kSinir       = Color(0xFF21262D);
const Color kSinirAcik   = Color(0xFF2A3550);
const Color kVurgu       = Color(0xFF00FF9C);
const Color kVurgu2      = Color(0xFF58A6FF);
const Color kMetin       = Color(0xFFE2E8F0);
const Color kMetinSoluk  = Color(0xFFAAB4BF);
const Color kMetinCok    = Color(0xFF6E8096);
const Color kHata        = Color(0xFFFF4757);
