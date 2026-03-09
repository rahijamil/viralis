import psycopg2
import random
import uuid
import datetime
import os

# Database connection parameters (can be overridden by environment variables)
DB_HOST = os.getenv('DB_HOST', 'localhost')
DB_PORT = os.getenv('DB_PORT', '5432')
DB_NAME = os.getenv('DB_NAME', 'viralis')
DB_USER = os.getenv('DB_USER', 'viralis')
DB_PASS = os.getenv('DB_PASS', 'viralis_pass')

def seed_database():
    try:
        conn = psycopg2.connect(
            host=DB_HOST,
            port=DB_PORT,
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASS
        )
        cur = conn.cursor()

        print("Connectivity established. Seeding database...")

        # 1. Get the admin user ID
        cur.execute("SELECT id FROM users WHERE email = 'admin@viralis.ai'")
        user_id = cur.fetchone()[0]

        # 2. Create some topics
        topics = [
            ('AI Agents', ['ai', 'agents', 'automation']),
            ('Clean Energy', ['solar', 'wind', 'renewables']),
            ('Space Exploration', ['mars', 'spacex', 'nasa']),
            ('Cybersecurity', ['hacking', 'security', 'privacy'])
        ]

        topic_ids = []
        for name, keywords in topics:
            cur.execute(
                "INSERT INTO topics (user_id, name, keywords, platforms) VALUES (%s, %s, %s, %s) RETURNING id",
                (user_id, name, keywords, ['twitter', 'reddit'])
            )
            topic_ids.append(cur.fetchone()[0])

        # 3. Create realistic trends
        trend_titles = [
            "New LLM breaks benchmarks",
            "Solar panel efficiency hits 40%",
            "Mars rover finds liquid water",
            "Major zero-day exploit patched",
            "Autonomous agents start coding",
            "Grid-scale batteries become cheaper",
            "Deep space signal detected",
            "Quantum computer solves encryption",
            "AI regulations debated in Senate",
            "Vertical farming startup raises $100M"
        ]

        sentiments = ['positive', 'neutral', 'controversial']

        for i in range(10):
            topic_id = random.choice(topic_ids)
            title = trend_titles[i]
            description = f"Detailed analysis of {title.lower()} and its impact on the industry."
            velocity_score = round(random.uniform(20.0, 95.0), 2)
            sentiment = random.choice(sentiments)
            detected_at = datetime.datetime.now() - datetime.timedelta(hours=random.randint(1, 48))
            
            cur.execute(
                """INSERT INTO trends (topic_id, title, description, velocity_score, sentiment, detected_at, ai_summary, sources) 
                   VALUES (%s, %s, %s, %s, %s, %s, %s, %s)""",
                (topic_id, title, description, velocity_score, sentiment, detected_at, 
                 f"AI summary for {title}", '{"source": "synthetic"}')
            )

        conn.commit()
        print(f"Successfully seeded {len(trend_titles)} trends and {len(topics)} topics.")

        cur.close()
        conn.close()

    except Exception as e:
        print(f"Error seeding database: {e}")

if __name__ == "__main__":
    seed_database()
