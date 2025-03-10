# Основные переменные
BUILD_DIR = dist
SRC_DIR = src
MODULES_DIR = $(SRC_DIR)/modules
SHELL = /bin/bash

# Имя результирующего файла
TARGET = install_remnawave.sh

# Список всех модулей в порядке включения
MODULES = $(MODULES_DIR)/shared/common.sh \
          $(MODULES_DIR)/shared/ui.sh \
          $(MODULES_DIR)/dependencies/dependencies.sh \
          $(MODULES_DIR)/remnawave_json/remnawave_json.sh \
          $(MODULES_DIR)/caddy/caddy.sh \
          $(MODULES_DIR)/panel/ui.sh \
          $(MODULES_DIR)/panel/vless-configuration.sh \
          $(MODULES_DIR)/panel/panel.sh \
          $(MODULES_DIR)/selfsteal/selfsteal.sh \
          $(MODULES_DIR)/node/node.sh

.PHONY: all
all: clean build

# Создание директории сборки
$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

# Сборка скрипта
.PHONY: build
build: $(BUILD_DIR)
	@echo "Сборка установщика Remnawave..."
	@# Удаляем предыдущую сборку, если она существует
	@rm -f $(BUILD_DIR)/$(TARGET)
	@echo '#!/bin/bash' > $(BUILD_DIR)/$(TARGET)
	@echo '' >> $(BUILD_DIR)/$(TARGET)
	@echo '# Remnawave Installer (модульная версия)' >> $(BUILD_DIR)/$(TARGET)
	@echo '# Собрано: $(shell date)' >> $(BUILD_DIR)/$(TARGET)
	@echo '' >> $(BUILD_DIR)/$(TARGET)
	
	@# Добавляем содержимое модулей, удаляя шебанг из каждого файла
	@for module in $(MODULES); do \
		echo "# Включение модуля: $$(basename $$module)" >> $(BUILD_DIR)/$(TARGET); \
		tail -n +2 $$module >> $(BUILD_DIR)/$(TARGET); \
		echo '' >> $(BUILD_DIR)/$(TARGET); \
	done
	
	@# Добавляем main.sh, пропуская блок импорта модулей
	@head -n 10 $(SRC_DIR)/main.sh | tail -n +2 >> $(BUILD_DIR)/$(TARGET)
	@echo '' >> $(BUILD_DIR)/$(TARGET)
	
	@# Добавляем остальную часть main.sh после блока импортов
	@tail -n +61 $(SRC_DIR)/main.sh >> $(BUILD_DIR)/$(TARGET)
	
	@# Делаем скрипт исполняемым
	@chmod +x $(BUILD_DIR)/$(TARGET)
	@echo "Установщик успешно собран: $(BUILD_DIR)/$(TARGET)"

# Очистка
.PHONY: clean
clean:
	@rm -rf $(BUILD_DIR)
	@echo "Директория сборки очищена."

# Установка
.PHONY: install
install: all
	@echo "Копирование скрипта в /usr/local/bin..."
	@sudo cp $(BUILD_DIR)/$(TARGET) /usr/local/bin/$(TARGET)
	@sudo chmod +x /usr/local/bin/$(TARGET)
	@echo "Установка завершена. Запустите '$(TARGET)' для установки Remnawave."

# Тестирование
.PHONY: test
test: all
	@echo "Проверка синтаксиса скрипта..."
	@bash -n $(BUILD_DIR)/$(TARGET)
	@echo "Синтаксис скрипта корректен."

# Отладка
.PHONY: debug
debug: all
	@echo "Запуск в режиме отладки..."
	@bash -x $(BUILD_DIR)/$(TARGET)
