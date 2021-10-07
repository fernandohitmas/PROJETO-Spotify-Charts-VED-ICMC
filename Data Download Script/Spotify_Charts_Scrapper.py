'''
Program copied and modified from the original work from hktosun in his github account
The main difference here is the utilization of the libraries futures to make parallel requests

This code...
Scrapes the Spotify Charts website, gets the necessary data from the Top 200 list 
(songs, artists, listen counts, and ranks in each country at each date), and
creates a separate data file for each country for which the data is available.
'''

import pandas as pd
import os
import requests
from bs4 import BeautifulSoup as bs
from datetime import timedelta, date
import time
from concurrent.futures import as_completed
from requests_futures.sessions import FuturesSession


# GLOBAL VARIABLES
HEADER = {
  "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/50.0.2661.75 Safari/537.36",
  "X-Requested-With": "XMLHttpRequest"
}


def date_interval():
    '''
    It generates a list of dates between Jan 1, 2017 and current date.
    FORMAT: YYYY-MM-DD
    '''    
    for day in pd.date_range(start = pd.to_date("2017-01-01"), end = date.today()):
        yield day


def create_links(country):
    '''
    It creates the list of page links we will get the data from.
    '''
    dates = date_interval()
    for single_date in date_interval(start_date, end_date):
        yield 'https://spotifycharts.com/regional/' + country + '/daily/' + single_date.strftime("%Y-%m-%d")


def get_data(country):
    '''
    It collects the data for each country, and write them in a list.
    The entries are (in order): Song, Artist, Date, Play Count, Rank
    '''
    links = create_links(country)
    rows = []
    with FuturesSession() as session:
        futures = [session.get(link,headers=HEADER) for link in links]
        for future in as_completed(futures):
            response = future.result()
            soup = bs(response.text, 'html.parser')
            entries = soup.find_all("td", class_ = "chart-table-track")
            streams = soup.find_all("td", class_="chart-table-streams")
            date = response.url.split('/')[-1]
            for i, (entry, stream) in enumerate(zip(entries,streams)):
                song = entry.find('strong').get_text()
                artist = entry.find('span').get_text()[3:]
                play_count = stream.get_text()
                rows.append([song, artist, date, play_count, i+1])
    return(rows)


def save_data(country):
    '''
    It exports the data for each coutnry in a csv format.
    The column names are Song, Artist, Date, Streams, Rank.
    '''
    if not os.path.exists('data'):
        os.makedirs('data')
    file_name = 'data/' + country[1].replace(" ", "_").lower() + '.csv'
    data = get_data(country[0])
    if(len(data)!= 0):
        data = pd.DataFrame(data, columns=['Song','Artist','Date', 'Streams','Rank'])
        data['Country'] = country[1]
        data.sort_values(by='Rank')
        data.to_csv(file_name, sep=',', float_format='%s',index = False)


def get_countries():
    '''
    It generates a list of countries for which the data is provided.
    '''
    print('Função get_countries!')

    session = requests.Session()
    page = session.get('https://spotifycharts.com/regional',headers=HEADER)
    soup = bs(page.content, 'html.parser')
    countries = []
    ctys = soup.find('ul').findAll("li")
    for cty in ctys:
        countries.append([cty["data-value"],cty.get_text()])
    return(countries)


def main():
    '''
    It runs the function save_data for each country.
    In other words, it creates the .csv data files for each country.
    '''
    countries = get_countries()    
    for country in countries:
        save_data(country)


if __name__ == "__main__":
    try:
        start_time = time.time()
        print("START:", time.ctime())

        main()
        
    finally:
        end_time = time.time()
        print("TIME PASSED:", round((end_time - start_time)/60,2),'min') 