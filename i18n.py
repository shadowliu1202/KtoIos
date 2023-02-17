import io
import os.path
import re
from typing import TextIO
import pandas as pd
import requests
import configparser
from pandas import ExcelFile, Series


def load_excel(url: str) -> ExcelFile:
    response = requests.get(url)
    bytes_file_obj = io.BytesIO()
    bytes_file_obj.write(response.content)
    bytes_file_obj.seek(0)
    return pd.ExcelFile(bytes_file_obj, engine="openpyxl")


def open_file(lang: str) -> TextIO:
    file_path = "./" + targetFolder + "/" + filename_culture_workaround_transform(lang) + ".lproj"
    os.makedirs(file_path, exist_ok=True)
    return open(file_path + "/Localizable.strings", "w")


def filename_culture_workaround_transform(culture_code: str) -> str:
    return "vi-vn" if (culture_code == "vi") else culture_code


def is_ignored_sheet(name: str) -> bool:
    is_ignored = False
    for tag in ignoredSheetTag:
        if tag in str(name):
            is_ignored = True
            break
    return is_ignored


def get_key(sheet_name: str, row: Series) -> str:
    return "{}_{}".format(sheet_name, row["Key"]).lower()


def get_value(lang: str, row: Series) -> str:
    cell_value = row.get(lang, "")
    value = "" if pd.isna(cell_value) else str(cell_value)
    value = re.sub("\{[\w\.]*\}", "%@", value)
    value = re.sub("%\.[0-9]+f", "%@", value)
    value = value \
        .replace("%s", "%@") \
        .replace("%d", "%@") \
        .replace("\"", "\\\"")
    return value


config = configparser.ConfigParser()
config.read('config.ini')

KEY_VALUE_TEMPLATE = "\"{}\" = \"{}\";\n"
URL_TEMPLATE = "https://docs.google.com/spreadsheet/ccc?key={}&output=xlsx"

SHEET_ID = config["DEFAULT"]["sheet_id"]
languages = config["DEFAULT"]["culture_codes"].split(',')
ignoredSheetTag = config["DEFAULT"]["ignored_sheet_tags"].split(',')
targetFolder = config["DEFAULT"]["target_folder"]

print(f"Downloading GoogleSheet... ", end="")
excel = load_excel(URL_TEMPLATE.format(SHEET_ID))
print("Done!")

for language in languages:
    print(f"Converting {language} file... ", end="")
    file = open_file(language)

    for sheetName in excel.sheet_names:
        if is_ignored_sheet(sheetName):
            continue
        sheet = pd.read_excel(excel, sheet_name=sheetName)
        file.write(f"\n//MARK: - {sheetName}\n")
        for index, item in sheet.iterrows():
            file.write(
                KEY_VALUE_TEMPLATE.format(get_key(sheet_name=sheetName, row=item), get_value(lang=language, row=item)))
    file.close()
    print("Done!")

print("All Done!")
