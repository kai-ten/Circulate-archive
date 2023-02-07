import React from 'react';
import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import HomepageFeatures from '@site/src/components/HomepageFeatures';

import styles from './index.module.css';

function HomepageHeader() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <header className={clsx('hero', styles.heroBanner)}>
      <div className="container">
        <h1 className="hero__title">{siteConfig.title} is the Open Source & Serverless ELT Platform for Cybersecurity Teams</h1>
        <p className="hero__subtitle">{siteConfig.tagline}</p>
        <br />
        <div className={styles.buttons}>
          <Link
            className="button button--primary button--lg"
            to="/docs/getting_started">
            Get Started
          </Link>
        </div>
      </div>
    </header>
  );
}

export default function Home() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <Layout
      title={`Open Source Serverless Data Integration Platform`}
      description="Circulate enables Cybersecurity teams to leverage all of their API data without having to maintain any servers. Highly scalable, highly available, and easy to deploy & maintain.">
      <HomepageHeader />
      <main>
        <HomepageFeatures />
      </main>
    </Layout>
  );
}
