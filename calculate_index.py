import pandas as pd
from sklearn.decomposition import PCA
from sklearn.preprocessing import StandardScaler
from sklearn.preprocessing import MinMaxScaler
import matplotlib.pyplot as plt
import numpy as np
import geopandas as gpd

df = pd.read_csv('index_raw.csv')
pop = pd.read_csv('other/census_clean.csv')

df.drop(df[df.zip == 10015].index, inplace = True) # Natalie identified this zipcode as one to drop
df = df.reset_index(drop = True)

arts_providers = ['independent_artists', 'art_firms', 'arts_organizations']
arts_dollars = ['total_revenue', 'total_compensation', 'total_expenses', 'contributed_revenue']
government_support = ['federal_awards', 'federal_dollars', 'state_awards', 'state_dollars']
index_variables = arts_providers + arts_dollars + government_support

years = df.year.unique()

# making a dictionary just to easily be able to iterate over all the years
year_df_dict = {}
for year in years:
    year_df_dict[year] = df[df.year == year]

# adding the population data
for year in year_df_dict.keys():
    year_df_dict[year] = year_df_dict[year].merge(pop, on = ['zip'])
    year_df_dict[year].dropna(inplace = True)
    year_df_dict[year].reset_index(drop = True, inplace = True)

'''
These are zipcodes I looked up on a map.  The ones on the left are really small, maybe just for one
big office building, and have a population less than 10.  The ones on the right are the bigger
zipcodes that encapsulate the smaller ones, so we're going to take the values from the smaller
ones and add them to the big ones.
'''
zip_transformation = {10165: 10017,
                     10170:10017,
                     10173:10017,
                     10167:10017,
                     10174:10017,
                     10168:10017,
                     10169:10017,
                     10177:10017,
                     10172:10017,
                     10171:10017,
                     10110:10036, 
                     10020:10019,
                     10112:10019,
                     10103:10019,
                     10162:10075,
                     10153:10022,
                     10152:10022,
                     10154:10022,
                     10110:10036,
                     10199:10001,
                     10119:10001,
                     10278:10007,
                     10279:10007,
                     10271:10005,
                     10111:10019,
                     10115:10027,
                     10311:10314,
                     11351:11356,
                     11359:11360,
                     11371:11369
                     }
zip_check = pd.read_csv('other/zip_check.csv')
zip_check.drop(zip_check[zip_check.zip == 10015].index, inplace = True) # the one Natalie said to drop
# these three were missing, they have text values that we don't want in our dictionary for now
# when they are added back in we'll need to drop these three lines
zip_check.drop(zip_check[zip_check.zip == 10065].index, inplace = True)
zip_check.drop(zip_check[zip_check.zip == 10075].index, inplace = True)
zip_check.drop(zip_check[zip_check.zip == 11005].index, inplace = True)
zip_check.reset_index(inplace = True)
# add the zips from Natalie's list to our dictionary
for zip_value, index in zip(zip_check.zip, zip_check.index):
    zip_transformation[zip_value] = int(zip_check.iloc[index, 3])

def replace_zips(df):
    '''
    operates on a dataframe, iterates over rows, if the zip of the row is a bad zipcode, it first adds all the
    values of that row to the bigger zip then drops that row
    '''
    iterdf = df.copy()
    new_df = df.copy()
    for old_zip in iterdf.zip:
        if old_zip in zip_transformation.keys():
            new_zip = zip_transformation[old_zip]
            for column_name in index_variables + ['population']:
                try:
                    old_zip_value = df.loc[df.zip == old_zip, column_name].item()
                except ValueError:
                    old_zip_value = 0
                try:
                    new_zip_value = df.loc[df.zip == new_zip, column_name].item()
                except ValueError:
                    new_zip_value = 0
                new_df.loc[new_df.zip == new_zip, column_name] = old_zip_value + new_zip_value
    for zip_code in zip_transformation.keys():
        new_df.drop(new_df[new_df.zip == zip_code].index, inplace = True)
    new_df.reset_index(drop = True, inplace = True)
    return new_df  

for year in year_df_dict.keys():
    year_df_dict[year] = replace_zips(year_df_dict[year])

# making the data per capita by dividing by population
for year in year_df_dict.keys():
    copy_df = year_df_dict[year].copy()
    for variable in index_variables:
        year_df_dict[year][variable] = copy_df[variable] / copy_df.population 

# standard normal scaling
sns_dict = year_df_dict.copy()
for year in sns_dict.keys():
    scaler = StandardScaler()
    snscaled = pd.DataFrame(scaler.fit_transform(sns_dict[year][index_variables]), columns = index_variables)
    snscaled['zip'] = year_df_dict[year].zip
    snscaled['year'] = year_df_dict[year].year
    snscaled['population'] = year_df_dict[year].population
    snscaled = snscaled[year_df_dict[year].columns.values]
    sns_dict[year] = snscaled

# doing the pca and calculating the index
for year in sns_dict.keys():
    pca = PCA(n_components = 1)
    sns_dict[year]['pca_arts_providers'] = pca.fit_transform(sns_dict[year][arts_providers])
    sns_dict[year]['pca_arts_dollars'] = pca.fit_transform(sns_dict[year][arts_dollars])
    sns_dict[year]['pca_government_support'] = pca.fit_transform(sns_dict[year][government_support])
    sns_dict[year]['vibrancy'] = 0.45*sns_dict[year]['pca_arts_providers'] + 0.45*sns_dict[year]['pca_arts_dollars'] + \
                                    0.1*sns_dict[year]['pca_government_support']

# taking all this info and adding it to the GeoJSON with the zips
zip_shapes = gpd.read_file('nyc_zips/nyc-zip-code-tabulation-areas-polygons.geojson')
zip_shapes.postalCode = zip_shapes.postalCode.apply(int)
zip_shapes = zip_shapes[['postalCode', 'geometry']]
zip_shapes.columns = ['zip', 'geometry']
geo_dict = sns_dict.copy()
for year in years:
    geo_dict[year] = zip_shapes.merge(sns_dict[year], on = 'zip')
    geo_dict[year]['rank'] = geo_dict[year].vibrancy.rank(method = 'dense')

# writing to files
geo_dict[2015].to_file('geojsons/zip_2015.geojson', driver = 'GeoJSON')
geo_dict[2014].to_file('geojsons/zip_2014.geojson', driver = 'GeoJSON')
geo_dict[2013].to_file('geojsons/zip_2013.geojson', driver = 'GeoJSON')
geo_dict[2012].to_file('geojsons/zip_2012.geojson', driver = 'GeoJSON')
geo_dict[2011].to_file('geojsons/zip_2011.geojson', driver = 'GeoJSON')
geo_dict[2010].to_file('geojsons/zip_2010.geojson', driver = 'GeoJSON')
geo_dict[2009].to_file('geojsons/zip_2009.geojson', driver = 'GeoJSON')
geo_dict[2008].to_file('geojsons/zip_2008.geojson', driver = 'GeoJSON')
geo_dict[2007].to_file('geojsons/zip_2007.geojson', driver = 'GeoJSON')
geo_dict[2006].to_file('geojsons/zip_2006.geojson', driver = 'GeoJSON')
geo_dict[2005].to_file('geojsons/zip_2005.geojson', driver = 'GeoJSON')