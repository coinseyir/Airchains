#!/bin/bash

# Geçici log dosyasının yolu
TEMP_LOG="/tmp/tracks_logfile.log"

while true; do
    # Uygulamayı başlat ve çıktısını dosyaya yönlendir
    ./tracks start | tee $TEMP_LOG &
    PID=$!
    echo "Uygulama başlatıldı, PID: $PID"

    # 10 dakikada bir yeniden başlat
    for i in {1..60}; do
        sleep 10

        # RPC hatası kontrolü
        if tail -n 10 $TEMP_LOG | grep -q "rpc error"; then
            echo "RPC hatası tespit edildi, uygulama durduruluyor..."
            kill $PID
            sleep 2
            
            echo "Rollback komutları çalıştırılıyor..."
            for j in {1..3}; do
                ./tracks rollback
                sleep 2
            done

            echo "Uygulama yeniden başlatılıyor..."
            break
        fi
    done

    echo "Uygulama 10 dakika çalıştı, yeniden başlatılıyor..."
    kill $PID
    sleep 5
done
