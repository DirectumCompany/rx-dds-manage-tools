# coding: utf-8
""" Модуль плагина для управления прикладными проектами """
import os
import os.path
from typing import Any, Optional
import termcolor
import pathlib

from py_common import process
from fire.formatting import Bold

from sungero_deploy.all import All
from sungero_deploy.static_controller import StaticController
from components.base_component import BaseComponent
from components.component_manager import ComponentManager, component, all_component_plugins
from components.component_searcher import ComponentSearcher
from py_common.logger import log
from sungero_deploy.deployment_tool import DeploymentTool
from sungero_deploy.services.sungero_web_client import SungeroWebClient
from common_plugin import yaml_tools, git_tools



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
        #self._static_controller.add_static(self._static_filesystem_path, self._static_url_path)
        log.info(f'"{self.__class__.__name__}" component has been successfully installed.')
        self._print_help_after_action()

    def current(self) -> None:
        show_config(self.config_path)

    def check_config(self, config_path: str) -> None:
        show_config(config_path)

    """
    def test(self, src_config_path: str, dst_config_path: str) -> None:
        pass
        import pprint
        pp = pprint.PrettyPrinter(indent=4)                
        src_config = yaml_tools.load_yaml_from_file(src_config_path)
        dst_config = yaml_tools.load_yaml_from_file(dst_config_path)
        #dst_config["variables"]["repositories"]  = src_config["variables"]["repositories"].copy() 
        dst_config["services_config"]["DevelopmentStudio"]['REPOSITORIES']["repository"]  = src_config["services_config"]["DevelopmentStudio"]['REPOSITORIES']["repository"].copy() 
        repos_as_str =""
        for repo in src_config["services_config"]["DevelopmentStudio"]['REPOSITORIES']["repository"]:
            repos_as_str += f'"folder={repo.get("@folderName")}, type={repo.get("@solutionType")}, url={repo.get("@url")}" '
        dst_config["variables"]["repositories"]  = repos_as_str
        yaml_tools.yaml_dump_to_file(dst_config, dst_config_path+"_tmp")
    """

    def set(self, project_config_path: str) -> None:
        while (True):
            show_config(project_config_path)
            answ = input("Переключиться на указанный проект? (y,n):")
            if answ=='y' or answ=='Y':
                # остановить сервисы
                all = All(self.config)
                all.down()

                # скорректировать etc\config.yml
                src_config = yaml_tools.load_yaml_from_file(project_config_path)
                dst_config = yaml_tools.load_yaml_from_file(self.config_path)
                dst_config["services_config"]["DevelopmentStudio"]['REPOSITORIES']["repository"]  = src_config["services_config"]["DevelopmentStudio"]['REPOSITORIES']["repository"].copy() 
                dst_config["variables"]["purpose"] = src_config["variables"]["purpose"]
                dst_config["variables"]["database"] = src_config["variables"]["database"]
                dst_config["variables"]["home_path"] = src_config["variables"]["home_path"]
                dst_config["variables"]["home_path_src"]  = src_config["variables"]["home_path_src"]
                yaml_tools.yaml_dump_to_file(dst_config, self.config_path)

                # поднять сервисы
                all2 = All(self.config)
                all2.config_up()
                all2.up()

                # обновить конфиг DDS
                from dds_plugin.development_studio import DevelopmentStudio
                DevelopmentStudio(self.config_path).generate_config_settings()
                break
            elif answ=='n' or answ=='N':
                break

    def uninstall(self) -> None:
        """
        Удалить компоненту.
        """
        #self._static_controller.remove_static(self._static_url_path)
        log.info(f'"{self.__class__.__name__}" component has been successfully uninstalled.')
        self._print_help_after_action()

    def generate_empty_project_config(self, new_config_path: str) -> None:
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
        else:
            log.error(f'Файл {new_config_path} уже существует.')

    @staticmethod
    def help() -> None:
        log.info('do map current - показать ключевую информацию из текущего config.yml')
        log.info('do map check_config <путь к yml-файлу> - показать ключевую информацию из указанного yml-файла описания проекта')
        log.info('do map set <путь к yml-файлу> - переключиться на проект, описаный в указанном yml-файла')
        log.info('do map generate_empty_project_config <путь к yml-файлу> - создаст заготовку для файла описания проекта')

def show_config(config_path):
    config = yaml_tools.load_yaml_from_file(_get_check_file_path(config_path))
    colorize = lambda x: termcolor.colored(x, color="green", attrs=["bold"])
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
        print(f'  folder: {colorize(repo.get("@folderName").ljust(maxlen)):} solutiontype: {colorize(repo.get("@solutionType"))}  url: {colorize(repo.get("@url"))}')

def _get_check_file_path(config_path: str) -> pathlib.Path:
    if not config_path:
        raise ValueError("config_path does not set.")
    p_config_path = pathlib.Path(config_path)
    if not p_config_path.is_file():
        log.error(f'Файл {config_path} не найден.')
        raise FileNotFoundError(f"'config_path' file not found: '{config_path}'")
    return p_config_path
