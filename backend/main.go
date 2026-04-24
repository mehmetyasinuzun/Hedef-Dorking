package main

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

type AramaIstegi struct {
	Sorgu string `json:"sorgu"`
}

type Yanit struct {
	Basarili bool        `json:"basarili"`
	Veri     interface{} `json:"veri,omitempty"`
	Mesaj    string      `json:"mesaj,omitempty"`
}

func main() {
	log.SetFlags(0)
	log.SetPrefix("")

	logDosya := logKur()
	if logDosya != nil {
		defer logDosya.Close()
	}

	http.HandleFunc("/api/ara", ara)

	logla("BASLATMA", "Sunucu calisiyor -> http://localhost:8080")
	if err := http.ListenAndServe(":8080", nil); err != nil {
		logla("HATA", "Sunucu durakladi: %v", err)
	}
}

func logKur() *os.File {
	exeYol, err := os.Executable()
	if err != nil {
		log.Printf("Executable yolu alinamadi: %v", err)
		return nil
	}

	// YYYY-MM-DD
	gun := time.Now().Format("2006-01-02")
	logYol := filepath.Join(filepath.Dir(exeYol), "dorking_"+gun+".log")

	dosya, err := os.OpenFile(logYol, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
	if err != nil {
		log.Printf("Log dosyasi acilamadi: %v", err)
		return nil
	}

	log.SetOutput(io.MultiWriter(os.Stdout, dosya))
	logla("BASLATMA", "Log dosyasi: %s", logYol)
	return dosya
}

func logla(etiket, format string, args ...interface{}) {
	zaman := time.Now().Format("2006-01-02 15:04:05")
	mesaj := fmt.Sprintf(format, args...)
	log.Printf("%s [%s] %s", zaman, etiket, mesaj)
}

func cevap(w http.ResponseWriter, kod int, basarili bool, veri interface{}, mesaj string) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(kod)
	_ = json.NewEncoder(w).Encode(Yanit{
		Basarili: basarili,
		Veri:     veri,
		Mesaj:    mesaj,
	})
}

func ara(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		cevap(w, 405, false, nil, "Sadece POST kabul edilir")
		return
	}

	var istek AramaIstegi
	if err := json.NewDecoder(r.Body).Decode(&istek); err != nil {
		logla("HATA", "/api/ara - gecersiz JSON: %v", err)
		cevap(w, 400, false, nil, "Gecersiz JSON")
		return
	}

	sorgu := strings.TrimSpace(istek.Sorgu)
	if sorgu == "" {
		cevap(w, 400, false, nil, "Arama sorgusu bos")
		return
	}

	googleURL := "https://www.google.com/search?q=" + url.QueryEscape(sorgu)
	if err := tarayicidaAc(googleURL); err != nil {
		logla("HATA", "Google acilamadi: %v", err)
		cevap(w, 500, false, nil, "Tarayici acilamadi")
		return
	}

	logla("ARA", "sorgu=%q", sorgu)
	cevap(w, 200, true, map[string]string{"acilan_url": googleURL}, "")
}

func tarayicidaAc(link string) error {
	return exec.Command("rundll32", "url.dll,FileProtocolHandler", link).Start()
}
