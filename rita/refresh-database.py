#!/usr/local/bin/python3.11

#import time
#import yaml
#import glob
import json
import os
#import threading
#from datetime import datetime
#import hashlib
import sys
import csv

from sqlalchemy.orm import scoped_session
from sqlalchemy.orm import sessionmaker
from sqlalchemy import create_engine, MetaData, Table, Column, Integer, String, Float, Text, DateTime, ForeignKey, text, select, update
from sqlalchemy.ext.declarative import declarative_base


# sqlalchemy ORM magic
Base = declarative_base()
#class Logs(Base):
    #__tablename__ = 'logs'
    #id = Column(Text, primary_key = True)
    #timestamp = Column(Text)
    #host = Column(Text, primary_key = True)
    #program = Column(Text)
    #message = Column(Text)

Base = declarative_base()
class Beacons(Base):
    __tablename__ = 'beacons'
    external = Column(String, primary_key = True)
    internal = Column(String, primary_key = True)
    type = Column(String, primary_key = True)
    score = Column(Float, primary_key = True)

class RitaLoader():
  def __init__(self, db_engine = None, db_session = None, db_lock = None):

    #self.elastalert_rules = self.load_elastalert_rules(glob.glob('/opt/elastalert/rules/*.yaml'))
    #print("[elastalert] %s" % self.elastalert_rules)
    #print("[sigma] %s" % self.sigma_rules)
    
    self.db_user = os.environ['DB_USER']
    self.db_password = os.environ['DB_PASSWORD']
    
    self.db_engine = create_engine('postgresql+psycopg2://%s:%s@threatintel-database/threatintel' % (self.db_user, self.db_password))
    self.db_session_factory = sessionmaker(bind=self.db_engine)
    self.db_session = scoped_session(self.db_session_factory)

    # DB setup from caller
    #self.db_engine = db_engine
    #self.db_session = db_session
    #self.db_lock = db_lock

    # Create sigma tables
    #with self.db_lock:
      #print("[sigma] Lock", file=sys.stderr, flush=True)
    Base.metadata.create_all(self.db_engine)
    #print("[sigma] Unlock", file=sys.stderr, flush=True)
    self.beacons = self.load_csv('/data/beacons.csv')
    #print("%s" % json.dumps(self.beacons, indent=4))
    #self.beacons_fqdn = self.load_csv('/beacons-fqdn.csv')
    #print("%s" % json.dumps(self.beacons_fqdn, indent=4))
    #self.beacons_proxy = self.load_csv('/beacons-proxy.csv')
    #print("%s" % json.dumps(self.beacons_proxy, indent=4))
    self.beacons_sni = self.load_csv('/data/beacons-sni.csv')
    #print("%s" % json.dumps(self.beacons_sni, indent=4))


  def load_csv(self, filename):
    with open(filename, newline='') as csvfile:
        csvdict = [row for row in csv.DictReader(csvfile)]
    return csvdict

  def parse_beacons(self):
    for record in self.beacons:
      internal = record['Source IP']
      external = record['Destination IP']
      score = record['Score']
      type = 'IP Beacon'
      self.push_beacon(external, internal, type, score)
    return

  def parse_beacons_fqdn(self):
    for record in self.beacons_fqdn:
      internal = record['Source IP']
      external = record['FQDN']
      score = record['Score']
      type = 'FQDN Beacon'
      self.push_beacon(external, internal, type, score)
    return

  def parse_beacons_proxy(self):
    return
  
  def parse_beacons_sni(self):
    for record in self.beacons_sni:
      internal = record['Source IP']
      external = record['SNI']
      score = record['Score']
      type = 'SNI Beacon'
      self.push_beacon(external, internal, type, score)
    return

  def clear_beacons(self):
    with self.db_session() as session:
      session.query(Beacons).delete()
      #session.delete(session.query(Beacons).all())
      #session.commit()


  def push_beacon(self, external, internal, type, score):
    print("[beacon] %s -> %s (%s) (%s)" % (internal, external, score, type))
    with self.db_session() as session:
      if len(session.execute(select(Beacons).where(Beacons.external == external, Beacons.internal == internal, Beacons.type == type, Beacons.score == score)).all()) == 0:
        session.add(Beacons(external = external, internal = internal, type = type, score = score))
      session.commit()
  
  def update_internal(self, record):    
    return

  def update_external(self, record):
    return

  def update_type(self, type):
    return

  def update_score(self, score):
    return

ritaloader = RitaLoader()
ritaloader.clear_beacons()
ritaloader.parse_beacons_sni()
ritaloader.parse_beacons()
#ritaloader.parse_beacons_fqdn()
#sigmarunner.load_sigma_rules()


#rules_pattern = '/sigma/rules/**/*.yml'
#es_rules_pattern = '/sigma/rules/**/*.es'
#sigma_runner = SigmaRunner(rules_pattern = es_rules_pattern, time_target = 60)

#for item in sigma_runner.scan_elastic():
#  print("%s" % json.dumps(item))
