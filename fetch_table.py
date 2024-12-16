from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from webdriver_manager.chrome import ChromeDriverManager
from bs4 import BeautifulSoup
import time

# Configure Selenium
options = Options()
options.binary_location = '/snap/bin/chromium'  # Update path if necessary
options.add_argument('--headless')
options.add_argument('--no-sandbox')
options.add_argument('--disable-dev-shm-usage')

# Launch Selenium with ChromeDriverManager
driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=options)
url = 'https://app.step.finance/en/history/latest?watching=3wr6taSTMEdDKUej5NWod2uGUC4wutem5dKJjEgEZntD'
driver.get(url)
time.sleep(10)  # Allow JavaScript to load
html_content = driver.page_source
driver.quit()

# Parse the table using BeautifulSoup
soup = BeautifulSoup(html_content, 'html.parser')
rows = soup.find_all('tr', class_='ant-table-row')

# Write extracted rows to a CSV file
with open('table_output.csv', 'w', encoding='utf-8') as f:
    for row in rows:
        cols = row.find_all('td')
        f.write(', '.join(col.get_text(strip=True).replace('\n', ' ') for col in cols) + '\n')
