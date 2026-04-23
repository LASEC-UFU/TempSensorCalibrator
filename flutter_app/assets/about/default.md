# Sobre — Temperature Sensor Calibrator

Aplicativo aberto desenvolvido pelo **LASEC / UFU** para **calibração de sensores de temperatura** diretamente no navegador, sem instalação.

Selecione um sensor no menu lateral para ver detalhes do **modelo matemático** específico (Steinhart–Hart, Callendar–Van Dusen, polinômio NIST...).

- **Repositório:** <https://github.com/LASEC-UFU/TempSensorCalibrator>
- **Tecnologia:** Flutter Web + WebAssembly
- **Arquitetura:** SOLID (cada sensor é uma implementação independente da interface `SensorModel`).
