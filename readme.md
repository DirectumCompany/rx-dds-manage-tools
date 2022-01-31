# rx-dds-manage-tools
Набор инструментов для расширенного управления рабочим местом прикладного работчика Directum RX.

## Описание 

Проект содержит 
1. Набор powershell-скриптов для упрощения прикладной разработки  для DirectumRX 3.3-4.1:
* change_project.ps1 - переключение между разными проектами прикладной разработки в рамках одной версии RX. Проект - это база данных + папки хранилища документов и предпросмотра + репозитории с исходниками
* change_rxversion.ps1 - переключение между разными версиями RX
* create_builds.ps1 - скрипт для создания комплектов при выпуске версии решения
* delete-appliedsolution.ps1 - очистка каталогов AppliedSolution
* remove-old-logs.ps1 - удаление логов различных сервисов RX 
* run_ro.ps1 - запуск DDS для конкретного проекта без возможности публикации (экспериментальная фича)
* start-rx.ps1 - запуск служб RX
* stop-rx.ps1 - остановка служб RX
* configrx\ - конфиги привязки к версиях RX
* samples\ - примеры конфигов проектов
2. Компоненту Manage Applied Projects для управления прикладными проектами в Directum RX 4.2
* ManageAppProjects\ - исходники компоненты
* ManageAppProjects_Component.zip - "пакет" компоенты для установки

Для запуска powershell-криптов может потребоваться изменение политики запуска PowerShell-скриптов:
```
set-executionpolicy remotesigned
```

В большинстве скриптов есть параметр *-help*, который выводит краткую справку.

# Изменения

## 03.01.2021
1. Добавленна поддержка RX 3.6
2. Изменен способ остановки/запуска сервиса DrxServiceRunnerLocal - уменьшена вероятность появления ошибок при попытке остановить процесс.
3. Примеры конфигов переведены из ANSI в UTF-8
4. В create_builds.ps1 изменены параметры запуска DDS - сейчас DDS завершает работу не дожидаясь завершения дочерних процессов, что сокращает время работы скрипта в случе сборки пакета с бинарниками.

## 17.02.2021
1. Добавлен configrx\_rx36_config_1.2.xml - файл привязки к RX 3.6.27

## 19.02.2021
1. В change_project.ps1 добавлено выделение цветом ключевых значений переменных их конфига проекта.
2. В create_builds.ps1 добавлена возможность копирования уникальных файлов в каждый комплект дистрибутива - см. в sample_create_builds_config узел <settings> -> <set_infos> -> <set_info> -> <file_info>. Это позволяет, например, добавить описание состава и инструкции по развертыванию в каждый комплект дистрибутива.

## 21.02.2021
1. В скрипе переключения между проектами (change_project.ps1):
* реализована возможность запуска скрипта не из текущего каталога
* добавлен параметр -confirm, который подавляет ожидание подтверждения пользователя перед выполнением операций
2. Доработаны скрипт формирования дистрибутивов (create_builds.ps1):
* добавлена возможность формирования архивой после создания комплекта дистрибутива

## 24.05.2021
1. Добавлена поддержка RX 4.0 - добавлен файл привязки к версии RX configrx\_rx40_config_1.1.xml 
2. Изменен способ отображения состояния процессов RX

## 25.06.2021
1. Исправлено отображение кириллицы при просмотре ps1-файлов на github.com
2. Добавлен пример описания проекта для RX 4.0
3. В change_project.ps1 сделано два режима вывода параметров проекта, на который происходит переключению. По умолчанию используется упрощенный формат, в котором выводятся
только ключевые параметры  - сервер, БД, корневые каталоги для документов и каталогов с исходными кодами, список подключаемых репозиториев. 
Параметром `-show_detail_info` можно включить детальный вывод параметров, который использовался раньше
3. Добавлена возможность назначать символические ссылки на корневые каталоги для документов и каталогов с исходными кодами. 
Это может понадобиться в ситуациях, когда при загрузке DDS возникает ошибка "Слишком длинный путь или имя файла. Полное имя файла должно содержать меньше 260 знаков, а имя каталога - меньше 248 знаков.".
Символические ссылки можно указать в файле описания проекта в разделе "<SymLinks>" - см. samples\sample_config_rx40.xml.
Если этот раздел не указан или пераметры в нём не означены - работает как раньше.

## 16.08.2021
1. Добавленна поддержка RX 4.1

## 25.11.2021
1. Добавлена возможность явно управлять тем, нужно или нет увеличивать номер билда при сборке дистрибутивов - см. параметр incrementversion
в sample_create_builds_config.xml

## 23.12.2021 
1. Добавлена поддержка (бета) переключения проектов для RX 4.2

## 25.01.2022
1. Добавлена компоненты Manage Applied Projects для переключения между прикладными проектами в RX 4.2