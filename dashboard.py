
import streamlit as st
import pandas as pd
import plotly.express as px

# page config
st.set_page_config(page_title="Shipment Orders Dashboard", layout="wide")

# title
st.title("🚚 Shipment Orders Analysis Dashboard")
st.markdown("---")

# load data
@st.cache_data
def load_data():
    df = pd.read_csv('shipment_orders_dataset.csv')
    df['Order Date'] = pd.to_datetime(df['Order Date'])
    df['Selling Price'] = df['List Price'] * (1 - df['Discount Percent'] / 100)
    df['Total Sales'] = df['Quantity'] * df['Selling Price']
    df['Unit Profit'] = df['Selling Price'] - df['cost price']
    return df

df = load_data()

# ── SIDEBAR FILTERS ──────────────────────────────
st.sidebar.header("Filters")
selected_category = st.sidebar.multiselect(
    "Select Category",
    options=df['Category'].unique(),
    default=df['Category'].unique()
)
selected_segment = st.sidebar.multiselect(
    "Select Segment",
    options=df['Segment'].unique(),
    default=df['Segment'].unique()
)
selected_region = st.sidebar.multiselect(
    "Select Region",
    options=df['Region'].unique(),
    default=df['Region'].unique()
)

# apply filters
df_filtered = df[
    (df['Category'].isin(selected_category)) &
    (df['Segment'].isin(selected_segment)) &
    (df['Region'].isin(selected_region))
]

# ── KPI CARDS ─────────────────────────────────────
st.subheader("Key Metrics")
col1, col2, col3, col4 = st.columns(4)
col1.metric("Total Sales", f"${df_filtered['Total Sales'].sum():,.0f}")
col2.metric("Total Orders", f"{df_filtered['Order Id'].nunique():,}")
col3.metric("Total Profit", f"${df_filtered['Unit Profit'].sum():,.0f}")
col4.metric("Avg Order Value", f"${df_filtered['Total Sales'].mean():,.0f}")

st.markdown("---")

# ── ROW 1 CHARTS ──────────────────────────────────
col1, col2 = st.columns(2)

with col1:
    st.subheader("Total Sales by Category")
    category_sales = df_filtered.groupby('Category')['Total Sales'].sum().reset_index()
    fig = px.bar(category_sales, x='Category', y='Total Sales',
                 color='Category', color_discrete_sequence=px.colors.qualitative.Set2)
    st.plotly_chart(fig, use_container_width=True)

with col2:
    st.subheader("Sales by Segment")
    segment_sales = df_filtered.groupby('Segment')['Total Sales'].sum().reset_index()
    fig = px.pie(segment_sales, names='Segment', values='Total Sales',
                 color_discrete_sequence=px.colors.qualitative.Pastel)
    st.plotly_chart(fig, use_container_width=True)

# ── ROW 2 CHARTS ──────────────────────────────────
col1, col2 = st.columns(2)

with col1:
    st.subheader("Monthly Sales Trend")
    df_filtered['Month'] = df_filtered['Order Date'].dt.to_period('M').astype(str)
    monthly_sales = df_filtered.groupby('Month')['Total Sales'].sum().reset_index()
    fig = px.line(monthly_sales, x='Month', y='Total Sales',
                  markers=True, color_discrete_sequence=['steelblue'])
    fig.update_xaxes(tickangle=45)
    st.plotly_chart(fig, use_container_width=True)

with col2:
    st.subheader("Sales by Ship Mode")
    ship_sales = df_filtered.groupby('Ship Mode')['Total Sales'].sum().reset_index()
    fig = px.bar(ship_sales, x='Total Sales', y='Ship Mode',
                 orientation='h', color='Ship Mode',
                 color_discrete_sequence=px.colors.qualitative.Set3)
    st.plotly_chart(fig, use_container_width=True)

# ── ROW 3 CHARTS ──────────────────────────────────
col1, col2 = st.columns(2)

with col1:
    st.subheader("Top 10 States by Sales")
    state_sales = df_filtered.groupby('State')['Total Sales'].sum().reset_index()
    state_sales = state_sales.sort_values('Total Sales', ascending=False).head(10)
    fig = px.bar(state_sales, x='Total Sales', y='State',
                 orientation='h', color_discrete_sequence=['coral'])
    st.plotly_chart(fig, use_container_width=True)

with col2:
    st.subheader("Profit by Category")
    profit_cat = df_filtered.groupby('Category')['Unit Profit'].sum().reset_index()
    fig = px.pie(profit_cat, names='Category', values='Unit Profit',
                 hole=0.4, color_discrete_sequence=px.colors.qualitative.Set1)
    st.plotly_chart(fig, use_container_width=True)

  ── RAW DATA ──────────────────────────────────────
st.markdown("---")
st.subheader("Raw Data")
if st.checkbox("Show Raw Data"):
    st.dataframe(df_filtered)
