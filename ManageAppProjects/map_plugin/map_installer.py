# coding: utf-8
""" Модуль плагина для управления прикладными проектами """
from typing import Optional
import termcolor
import pathlib
import time

from fire.formatting import Bold

from sungero_deploy.all import All
from sungero_deploy.static_controller import StaticController
from components.base_component import BaseComponent
from components.component_manager import component
from py_common.logger import log
from sungero_deploy.deployment_tool import DeploymentTool
from common_plugin import yaml_tools
from sungero_deploy.scripts_config import get_config_model
from sungero_deploy.tools.sungerodb import SungeroDB
from sungero_deploy.tools.rxcmd import RxCmd

MANAGE_APPLIED_PROJECTS_ALIAS = 'map'

@component(alias=MANAGE_APPLIED_PROJECTS_ALIAS)
class ManageAppliedProject(BaseComponent):
    """ Компонент Изменение проекта. """

    def __init__(self, config_path: Optional[str] = None) -> None:
        """
        Конструктор.

        Args:
            config_path: Путь к конфигу.
        """
        super(self.__class__, self).__init__(config_path)
        self._static_controller = StaticController(self.config_path)

    def install(self) -> None:
        """
        Установить компоненту.
        """
        log.info(f'"{self.__class__.__name__}" component has been successfully installed.')
        self._print_help_after_action()

    def uninstall(self) -> None:
        """
        Удалить компоненту.
        """
        log.info(f'"{self.__class__.__name__}" component has been successfully uninstalled.')
        self._print_help_after_action()

    def current(self) -> None:
        """ Показать параметры текущего проекта """
        show_config(self.config_path)

    def check_config(self, config_path: str) -> None:
        """ Показать содержимое указанного файла описания проекта

        Args:
            config_path: путь к файлу с описанием проекта
        """
        show_config(config_path)


    def create_project(self, project_config_path: str, package_path:str, need_import_src:bool = False, confirm: bool = True) -> None:
        """ Создать новый прикладной проект (эксперементальная фича).
        Будет создана БД, в неё будет принят пакет разработки и стандратные шаблоны.

        Args:
            project_config_path: путь к файлу с описанием проекта
            package_path: путь к пакету разработки, который должен содержать бинарники
            need_import_src: признак необходимости принять исходники из указанного пакета разработки. По умолчанию - False
            confirm: признак необходимости выводить запрос на создание проекта. По умолчанию - True
        """
        while (True):
            show_config(project_config_path)
            answ = input("Создать новый проект? (y,n):") if confirm else 'y'
            if answ=='y' or answ=='Y':
                # остановить сервисы
                log.info(colorize("Остановка сервисов"))
                all = All(self.config)
                all.down()

                # скорректировать etc\config.yml
                log.info(colorize("Корректировка config.yml"))
                src_config = yaml_tools.load_yaml_from_file(project_config_path)
                dst_config = yaml_tools.load_yaml_from_file(self.config_path)
                dst_config["services_config"]["DevelopmentStudio"]['REPOSITORIES']["repository"]  = src_config["services_config"]["DevelopmentStudio"]['REPOSITORIES']["repository"].copy()
                dst_config["variables"]["purpose"] = src_config["variables"]["purpose"]
                dst_config["variables"]["database"] = src_config["variables"]["database"]
                dst_config["variables"]["home_path"] = src_config["variables"]["home_path"]
                dst_config["variables"]["home_path_src"]  = src_config["variables"]["home_path_src"]
                yaml_tools.yaml_dump_to_file(dst_config, self.config_path)
                time.sleep(2)

                # создать БД
                log.info(colorize("Создать БД"))
                exitcode = SungeroDB(get_config_model(self.config_path)).up()
                if exitcode == -1:
                    log.error(f'Ошибка при создании БД')
                    return

                # поднять сервисы
                log.info(colorize("Подъем сервисов"))
                all2 = All(get_config_model(self.config_path))
                all2.config_up()
                all2.up()

                # обновить конфиг DDS
                log.info(colorize("Обновление конфига DDS"))
                from dds_plugin.development_studio import DevelopmentStudio
                DevelopmentStudio(self.config_path).generate_config_settings()

                # принять пакет разработки в БД
                log.info(colorize("Ожидание загрузки сервисов"))
                time.sleep(30) #подождать, когда сервисы загрузятся - без этого возникает ошибка
                log.info(colorize("Прием пакета разработки"))
                DeploymentTool(self.config_path).deploy(package = package_path, init = True)

                # импортировать шаблоны
                log.info(colorize("Ожидание загрузки сервисов"))
                time.sleep(30) #подождать, когда сервисы загрузятся - без этого возникает ошибка
                log.info(colorize("Импорт шаблонов"))
                RxCmd(get_config_model(self.config_path)).import_templates()

                # принять пакет разработки в БД
                if need_import_src:
                    log.info(colorize("Прием пакета разработки"))
                    time.sleep(30) #подождать, когда сервисы загрузятся
                    DevelopmentStudio(self.config_path).run(f'--import-package {package_path}')

                log.info("")
                log.info(colorize("Новые параметры:"))
                self.current()
                break
            elif answ=='n' or answ=='N':
                break

    def set(self, project_config_path: str, confirm: bool = True) -> None:
        """ Переключиться на указанный прикладной проект

        Args:
            project_config_path: путь к файлу с описанием проекта
            confirm: признак необходимости выводить запрос на создание проекта. По умолчанию - True
        """
        while (True):
            show_config(project_config_path)
            answ = input("Переключиться на указанный проект? (y,n):") if confirm else 'y'
            if answ=='y' or answ=='Y':
                # остановить сервисы
                log.info(colorize("Остановка сервисов"))
                all = All(self.config)
                all.down()

                # скорректировать etc\config.yml
                log.info(colorize("Корректировка config.yml"))
                src_config = yaml_tools.load_yaml_from_file(project_config_path)
                dst_config = yaml_tools.load_yaml_from_file(self.config_path)
                dst_config["services_config"]["DevelopmentStudio"]['REPOSITORIES']["repository"]  = src_config["services_config"]["DevelopmentStudio"]['REPOSITORIES']["repository"].copy()
                dst_config["variables"]["purpose"] = src_config["variables"]["purpose"]
                dst_config["variables"]["database"] = src_config["variables"]["database"]
                dst_config["variables"]["home_path"] = src_config["variables"]["home_path"]
                dst_config["variables"]["home_path_src"]  = src_config["variables"]["home_path_src"]
                yaml_tools.yaml_dump_to_file(dst_config, self.config_path)
                time.sleep(2)

                # поднять сервисы
                log.info(colorize("Подъем сервисов"))
                all2 = All(get_config_model(self.config_path))
                all2.config_up()
                all2.up()

                # обновить конфиг DDS
                log.info(colorize("Обновление конфига DDS"))
                from dds_plugin.development_studio import DevelopmentStudio
                DevelopmentStudio(self.config_path).generate_config_settings()

                log.info("")
                log.info(colorize("Новые параметры:"))
                self.current()
                break
            elif answ=='n' or answ=='N':
                break

    def generate_empty_project_config(self, new_config_path: str) -> None:
        """ Создать новый файл с описанием проекта

        Args:
            new_config_path - путь к файлу, который нужно создать
        """
        template_config="""# ключевые параметры проекта
variables:
    # Назначение проекта
    purpose: '<Назначение проекта>'
    # БД проекта
    database: '<База данных>'
    # Домашняя директория, относительно которой хранятся все данные сервисов.
    # Используется только в конфигурационном файле.
    home_path: '<Домашний каталог>'
    # Корневой каталог c репозиториями проекта
    home_path_src: '<корневой каталог репозитория проекта>'
# репозитории
services_config:
    DevelopmentStudio:
        REPOSITORIES:
            repository:
            -   '@folderName': '<папка репозитория-1>'
                '@solutionType': 'Work'
                '@url': '<url репозитория-1>'
            -   '@folderName': '<папка репозитория-2>'
                '@solutionType': 'Base'
                '@url': '<url репозитория-2>'
"""
        p_config_path = pathlib.Path(new_config_path)
        if not p_config_path.exists():
            with open(new_config_path, 'w', encoding='utf-8') as f:
                f.write(template_config)
            log.info(colorize(f'Создан файл описания проекта {new_config_path}.'))
        else:
            log.error(f'Файл {new_config_path} уже существует.')

    @staticmethod
    def help() -> None:
        log.info('do map current - показать ключевую информацию из текущего config.yml')
        log.info('do map check_config <путь к yml-файлу> - показать ключевую информацию из указанного yml-файла описания проекта')
        log.info('do map set <путь к yml-файлу> - переключиться на проект, описаный в указанном yml-файла')
        log.info('do map generate_empty_project_config <путь к yml-файлу> - создаст заготовку для файла описания проекта')

def colorize(x):
    return termcolor.colored(x, color="green", attrs=["bold"])

def show_config(config_path):
    config = yaml_tools.load_yaml_from_file(_get_check_file_path(config_path))
    vars = config.get("variables")
    repos = config.get("services_config").get("DevelopmentStudio").get('REPOSITORIES').get("repository")
    maxlen = 0
    for repo in repos:
        if maxlen < len(repo.get("@folderName")):
            maxlen = len(repo.get("@folderName"))
    log.info(Bold(f'Назначение:    {vars.get("purpose")}'))
    log.info(f'database:      {colorize(vars.get("database"))}')
    log.info(f'home_path:     {colorize(vars.get("home_path"))}')
    log.info(f'home_path_src: {colorize(vars.get("home_path_src"))}')
    log.info('repositories:')
    for repo in repos:
        log.info(f'  folder: {colorize(repo.get("@folderName").ljust(maxlen)):} solutiontype: {colorize(repo.get("@solutionType"))}  url: {colorize(repo.get("@url"))}')

def _get_check_file_path(config_path: str) -> pathlib.Path:
    if not config_path:
        raise ValueError("config_path does not set.")
    p_config_path = pathlib.Path(config_path)
    if not p_config_path.is_file():
        log.error(f'Файл {config_path} не найден.')
        raise FileNotFoundError(f"'config_path' file not found: '{config_path}'")
    return p_config_path
