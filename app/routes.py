from flask import Flask, render_template
import pymysql.cursors

app = Flask(__name__)

# AWS RDS configuration
db_config = {
    'user': 'postgres',
    'password': 'postgres',
    'host': 'aurora-mysql-cluster.cluster-c3c60q4mqh22.us-east-1.rds.amazonaws.com',
    'database': 'mavenmovies',
    'cursorclass': pymysql.cursors.DictCursor
}

# Connect to the database
connection = pymysql.connect(**db_config)

@app.route('/')
def index():
    # Fetch data from RDS
    with connection.cursor() as cursor:
        sql = "SELECT * FROM film"
        cursor.execute(sql)
        data = cursor.fetchall()
    return render_template('index.html', data=data)

if __name__ == '__main__':
    app.run(debug=True)
